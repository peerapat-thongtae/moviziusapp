import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';
import '../models/search_filters.dart';

/// Paginated result state for a search tab. Holds the accumulated [items], the
/// active [filters] (discover mode), the active [query] (search mode), and the
/// cursor needed for infinite scroll.
///
/// When [query] is non-empty the tab is in **search mode** (`/search` endpoint).
/// When [query] is empty it is in **discover mode** (`/discover` endpoint).
@immutable
class SearchState<T> {
  const SearchState({
    this.items = const [],
    this.filters = const SearchFilters(),
    this.query = '',
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<T> items;
  final SearchFilters filters;
  final String query;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  bool get isSearchMode => query.isNotEmpty;

  SearchState<T> copyWith({
    List<T>? items,
    SearchFilters? filters,
    String? query,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchState<T>(
      items: items ?? this.items,
      filters: filters ?? this.filters,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

bool _hasMore(int page, int totalPages, int resultCount) =>
    totalPages > 0 ? page < totalPages : resultCount > 0;

abstract class _SearchNotifier<T> extends AsyncNotifier<SearchState<T>> {
  MediaKind get mediaKind;

  Future<({List<T> items, int totalPages})> fetchDiscover(
    int page,
    SearchFilters filters,
  );

  Future<({List<T> items, int totalPages})> fetchSearch(String q, int page);

  SearchFilters _filters = const SearchFilters();
  String _query = '';

  @override
  Future<SearchState<T>> build() async {
    final res = await fetchDiscover(1, _filters);
    return SearchState<T>(
      items: res.items,
      filters: _filters,
      query: '',
      page: 1,
      hasMore: _hasMore(1, res.totalPages, res.items.length),
    );
  }

  /// Updates the free-text search query. Empty string returns to discover mode.
  Future<void> setQuery(String query) async {
    _query = query.trim();
    state = const AsyncLoading();
    if (_query.isEmpty) {
      state = await AsyncValue.guard(() async {
        final res = await fetchDiscover(1, _filters);
        return SearchState<T>(
          items: res.items,
          filters: _filters,
          query: '',
          page: 1,
          hasMore: _hasMore(1, res.totalPages, res.items.length),
        );
      });
    } else {
      state = await AsyncValue.guard(() async {
        final res = await fetchSearch(_query, 1);
        return SearchState<T>(
          items: res.items,
          filters: _filters,
          query: _query,
          page: 1,
          hasMore: _hasMore(1, res.totalPages, res.items.length),
        );
      });
    }
  }

  /// Replaces discover filters and reloads from page 1. No-op in search mode.
  Future<void> setFilters(SearchFilters filters) async {
    if (_query.isNotEmpty) return;
    _filters = filters;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await fetchDiscover(1, _filters);
      return SearchState<T>(
        items: res.items,
        filters: _filters,
        query: '',
        page: 1,
        hasMore: _hasMore(1, res.totalPages, res.items.length),
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final next = current.page + 1;
    try {
      final res = current.isSearchMode
          ? await fetchSearch(_query, next)
          : await fetchDiscover(next, current.filters);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...res.items],
          page: next,
          hasMore: _hasMore(next, res.totalPages, res.items.length),
          isLoadingMore: false,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('SearchNotifier.loadMore failed: $e\n$stackTrace');
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

class MovieSearchNotifier extends _SearchNotifier<Movie> {
  @override
  MediaKind get mediaKind => MediaKind.movie;

  @override
  Future<({List<Movie> items, int totalPages})> fetchDiscover(
    int page,
    SearchFilters filters,
  ) async {
    final res = await ref
        .read(movieServiceProvider)
        .discoverCatalog(page: page, params: filters.toQueryParams(mediaKind));
    return (
      items: res.results.where((m) => m.posterPath.isNotEmpty).toList(),
      totalPages: res.totalPages,
    );
  }

  @override
  Future<({List<Movie> items, int totalPages})> fetchSearch(
    String q,
    int page,
  ) async {
    final res =
        await ref.read(movieServiceProvider).search(q, page: page);
    return (
      items: res.results.where((m) => m.posterPath.isNotEmpty).toList(),
      totalPages: res.totalPages,
    );
  }
}

class TvSearchNotifier extends _SearchNotifier<TvShow> {
  @override
  MediaKind get mediaKind => MediaKind.tv;

  @override
  Future<({List<TvShow> items, int totalPages})> fetchDiscover(
    int page,
    SearchFilters filters,
  ) async {
    final res = await ref
        .read(seriesServiceProvider)
        .discover(page: page, params: filters.toQueryParams(mediaKind));
    return (
      items: res.results.where((s) => s.posterPath.isNotEmpty).toList(),
      totalPages: res.totalPages,
    );
  }

  @override
  Future<({List<TvShow> items, int totalPages})> fetchSearch(
    String q,
    int page,
  ) async {
    final res =
        await ref.read(seriesServiceProvider).search(q, page: page);
    return (
      items: res.results.where((s) => s.posterPath.isNotEmpty).toList(),
      totalPages: res.totalPages,
    );
  }
}

final movieSearchProvider =
    AsyncNotifierProvider<MovieSearchNotifier, SearchState<Movie>>(
      MovieSearchNotifier.new,
    );

final tvSearchProvider =
    AsyncNotifierProvider<TvSearchNotifier, SearchState<TvShow>>(
      TvSearchNotifier.new,
    );
