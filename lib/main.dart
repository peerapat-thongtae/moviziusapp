import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_notifier.dart';
import 'core/auth/auth_state.dart';
import 'core/constants/app_config.dart';
import 'core/notifications/providers.dart';
import 'core/router/app_router.dart';
import 'core/router/route_paths.dart';
import 'core/theme/app_theme.dart';
import 'features/watchlist/providers/tv_watchlist_provider.dart';
import 'features/watchlist/providers/watchlist_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MoviziusApp()));
}

class MoviziusApp extends ConsumerStatefulWidget {
  const MoviziusApp({super.key});

  @override
  ConsumerState<MoviziusApp> createState() => _MoviziusAppState();
}

class _MoviziusAppState extends ConsumerState<MoviziusApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(fcmServiceProvider).initialize();
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    // App backgrounded → tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App terminated → opened via notification
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handleNotificationTap(initial);
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == 'tv_airing_today') {
      ref.read(goRouterProvider).go(RoutePaths.calendar);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-fetch the signed-in user's watchlists whenever the app returns to the
  /// foreground. The login `ref.listen` below only fires on the transition into
  /// [AuthAuthenticated], so a warm resume from the background (where the auth
  /// state never changes) would otherwise leave the watchlists stale.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(authNotifierProvider) is AuthAuthenticated) {
      _refreshWatchlists();
    }
  }

  void _refreshWatchlists() {
    ref.read(watchlistNotifierProvider.notifier).refresh();
    ref.read(tvWatchlistNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _refreshWatchlists();
        ref.read(fcmServiceProvider).registerCurrentToken();
      } else if (next is AuthUnauthenticated) {
        ref.invalidate(watchlistNotifierProvider);
        ref.invalidate(tvWatchlistNotifierProvider);
      }
    });

    if (authState is AuthLoading) {
      return MaterialApp(
        theme: AppTheme.light(),
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.dark(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Movizius',
      themeMode: ThemeMode.dark,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}
