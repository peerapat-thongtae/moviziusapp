import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/home_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/explore/pages/explore_page.dart';
import '../../features/home/pages/continue_watching_page.dart';
import '../../features/movies/models/movie_discover_response.dart';
import '../../features/movies/pages/movie_detail_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/search/pages/search_page.dart';
import '../../features/series/models/tv_discover_response.dart';
import '../../features/series/pages/series_detail_page.dart';
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
          final extra = state.extra;
          final movie = extra is Movie ? extra : null;
          final title = extra is String ? extra : movie?.title;
          return MovieDetailPage(movieId: id, title: title, movie: movie);
        },
      ),
      GoRoute(
        path: RoutePaths.seriesDetail,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra;
          final show = extra is TvShow ? extra : null;
          final title = extra is String ? extra : show?.name;
          return SeriesDetailPage(seriesId: id, title: title, show: show);
        },
      ),
      GoRoute(
        path: RoutePaths.continueWatching,
        builder: (context, state) => const ContinueWatchingPage(),
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
