import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/media_poster_card.dart';
import '../../movies/models/movie_discover_response.dart';
import '../../search/providers/search_providers.dart';
import '../../search/widgets/search_results_grid.dart';
import '../providers/library_provider.dart';

const _statuses = ['watchlist', 'watched'];
const _statusLabels = ['Watchlist', 'Watched'];

class MovieLibraryPage extends ConsumerStatefulWidget {
  const MovieLibraryPage({super.key});

  @override
  ConsumerState<MovieLibraryPage> createState() => _MovieLibraryPageState();
}

class _MovieLibraryPageState extends ConsumerState<MovieLibraryPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: _statuses.length, vsync: this)
    ..addListener(_onTabChanged);

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref
        .read(movieLibraryProvider.notifier)
        .setStatus(_statuses[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(movieLibraryProvider.notifier);
    final status = ref.watch(
      movieLibraryProvider.select((s) => s.value?.status ?? 'watchlist'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SearchResultsGrid<Movie>(
          key: ValueKey(status),
          state: ref.watch(movieLibraryProvider).whenData(
            (s) => SearchState(items: s.items, isLoadingMore: s.isLoadingMore),
          ),
          onRefresh: () async => notifier.setStatus(status),
          onLoadMore: notifier.loadMore,
          card: (context, movie) => MediaPosterCard(
            posterPath: movie.posterPath,
            title: movie.title,
            onTap: () => context.push(
              RoutePaths.movieDetailPath(movie.id),
              extra: movie,
            ),
          ),
        ),
      ),
    );
  }
}
