import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/home_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/explore/pages/explore_page.dart';
import '../../features/movies/pages/movie_detail_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/search/pages/search_page.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import 'go_router_refresh_stream.dart';
import 'main_shell.dart';
import 'route_observer.dart';
import 'route_paths.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.login,
    observers: [routeObserver],
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
        path: RoutePaths.movieDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final title = state.extra as String?;
          return MovieDetailPage(movieId: id, title: title);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.search,
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.explore,
                builder: (context, state) => const ExplorePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
