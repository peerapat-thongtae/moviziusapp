import 'dart:async';

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

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(movieSearchProvider.notifier).setQuery(value);
      ref.read(tvSearchProvider.notifier).setQuery(value);
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() => _query = '');
    ref.read(movieSearchProvider.notifier).setQuery('');
    ref.read(tvSearchProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final isSearchMode = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search movies & TV series…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _query.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close),
                      onPressed: _clearQuery,
                    ),
            ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Airing Today',
            onPressed: () => context.push(RoutePaths.calendar),
          ),
        ],
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
        children: [
          _MovieSearchTab(isSearchMode: isSearchMode),
          _TvSearchTab(isSearchMode: isSearchMode),
        ],
      ),
    );
  }
}

class _MovieSearchTab extends ConsumerWidget {
  const _MovieSearchTab({required this.isSearchMode});

  final bool isSearchMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(movieSearchProvider.notifier);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isSearchMode
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SearchFilterBar(
                    kind: MediaKind.movie,
                    onChanged: notifier.setFilters,
                  ),
                ),
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
  const _TvSearchTab({required this.isSearchMode});

  final bool isSearchMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tvSearchProvider.notifier);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isSearchMode
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SearchFilterBar(
                    kind: MediaKind.tv,
                    onChanged: notifier.setFilters,
                  ),
                ),
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
