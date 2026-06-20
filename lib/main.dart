import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_notifier.dart';
import 'core/auth/auth_state.dart';
import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/watchlist/providers/watchlist_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const ProviderScope(child: MoviziusApp()));
}

class MoviziusApp extends ConsumerWidget {
  const MoviziusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        ref.read(watchlistNotifierProvider.notifier).refresh();
      } else if (next is AuthUnauthenticated) {
        ref.invalidate(watchlistNotifierProvider);
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
