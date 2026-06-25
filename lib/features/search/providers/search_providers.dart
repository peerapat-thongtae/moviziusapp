import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';
import '../models/search_filters.dart';

/// Paginated, filtered result state for a search tab. Holds the accumulated
/// [items], the active [filters], and the cursor needed for infinite scroll.
@immutable
class SearchState<T> {
  const SearchState({
    this.items = const [],
    this.filters = const SearchFilters(),
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<T> items;
  final SearchFilters filters;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  SearchState<T> copyWith({
    List<T>? items,
    SearchFilters? filters,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchState<T>(
      items: items ?? this.items,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

bool _hasMore(int page, int totalPages, int resultCount) =>
    totalPages > 0 ? page < totalPages : resultCount > 0;

/// Shared infinite-scroll + filter behaviour for both catalogs. Subclasses
/// supply [fetch] (which catalog/params) and [mediaKind]; this base owns the
/// pagination, filter swapping, and load-more guards.
abstract class _SearchNotifier<T> extends AsyncNotifier<SearchState<T>> {
  MediaKind get mediaKind;

  /// Fetches one page for the given [filters].
  Future<({List<T> items, int totalPages})> fetch(
    int page,
    SearchFilters filters,
  );

  SearchFilters _filters = const SearchFilters();

  @override
  Future<SearchState<T>> build() async {
    final res = await fetch(1, _filters);
    return SearchState<T>(
      items: res.items,
      filters: _filters,
      page: 1,
      hasMore: _hasMore(1, res.totalPages, res.items.length),
    );
  }

  /// Replaces the active filters and reloads from page 1 (shows the loading
  /// skeleton again). Called debounced from the filter bar.
  Future<void> setFilters(SearchFilters filters) async {
    _filters = filters;
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Appends the next page. No-ops when exhausted or a fetch is in flight;
  /// failures are logged and swallowed so the next scroll can retry.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final next = current.page + 1;
    try {
      final res = await fetch(next, current.filters);
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
  Future<({List<Movie> items, int totalPages})> fetch(
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
}

class TvSearchNotifier extends _SearchNotifier<TvShow> {
  @override
  MediaKind get mediaKind => MediaKind.tv;

  @override
  Future<({List<TvShow> items, int totalPages})> fetch(
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
}

final movieSearchProvider =
    AsyncNotifierProvider<MovieSearchNotifier, SearchState<Movie>>(
      MovieSearchNotifier.new,
    );

final tvSearchProvider =
    AsyncNotifierProvider<TvSearchNotifier, SearchState<TvShow>>(
      TvSearchNotifier.new,
    );
