import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/media_poster_card.dart';
import '../../movies/models/movie_discover_response.dart';
import '../../series/models/tv_discover_response.dart';
import '../models/search_filters.dart';
import '../providers/search_providers.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_results_grid.dart';

/// Search experience: two tabs (Movies / TV Series), each with a debounced
/// search box, a filter bar (sort / genre / year / min rating) and a 2-column
/// poster grid backed by the discover endpoints. The two tabs are intentionally
/// symmetric (see CLAUDE.md) — they differ only in their data binding.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Series'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MovieSearchTab(),
          _TvSearchTab(),
        ],
      ),
    );
  }
}

class _MovieSearchTab extends ConsumerWidget {
  const _MovieSearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(movieSearchProvider.notifier);
    return Column(
      children: [
        SearchFilterBar(
          kind: MediaKind.movie,
          onChanged: notifier.setFilters,
        ),
        Expanded(
          child: SearchResultsGrid<Movie>(
            state: ref.watch(movieSearchProvider),
            onRefresh: () async => ref.invalidate(movieSearchProvider),
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
      ],
    );
  }
}

class _TvSearchTab extends ConsumerWidget {
  const _TvSearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tvSearchProvider.notifier);
    return Column(
      children: [
        SearchFilterBar(
          kind: MediaKind.tv,
          onChanged: notifier.setFilters,
        ),
        Expanded(
          child: SearchResultsGrid<TvShow>(
            state: ref.watch(tvSearchProvider),
            onRefresh: () async => ref.invalidate(tvSearchProvider),
            onLoadMore: notifier.loadMore,
            card: (context, show) => MediaPosterCard(
              posterPath: show.posterPath,
              title: show.name,
              onTap: () => context.push(
                RoutePaths.seriesDetailPath(show.id),
                extra: show,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
