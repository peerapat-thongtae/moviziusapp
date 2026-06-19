import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/home_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final atLogin = state.matchedLocation == RoutePaths.login;

      if (authState is AuthAuthenticated) {
        return atLogin ? RoutePaths.home : null;
      }
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return atLogin ? null : RoutePaths.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});
