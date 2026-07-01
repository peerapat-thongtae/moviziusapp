import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';

/// Paginated result state for a profile library tab, filtered by the TMDB
/// `with_account_status` value (`watchlist`, `watching`, `watched`).
@immutable
class LibraryState<T> {
  const LibraryState({
    this.items = const [],
    this.status = 'watchlist',
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<T> items;
  final String status;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  LibraryState<T> copyWith({
    List<T>? items,
    String? status,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return LibraryState<T>(
      items: items ?? this.items,
      status: status ?? this.status,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

bool _hasMore(int page, int totalPages, int resultCount) =>
    totalPages > 0 ? page < totalPages : resultCount > 0;

abstract class _LibraryNotifier<T> extends AsyncNotifier<LibraryState<T>> {
  Future<({List<T> items, int totalPages})> fetchByStatus(
    String status,
    int page,
  );

  @override
  Future<LibraryState<T>> build() async {
    const status = 'watchlist';
    final res = await fetchByStatus(status, 1);
    return LibraryState<T>(
      items: res.items,
      status: status,
      page: 1,
      hasMore: _hasMore(1, res.totalPages, res.items.length),
    );
  }

  /// Switches the active account-status tab and reloads from page 1.
  Future<void> setStatus(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await fetchByStatus(status, 1);
      return LibraryState<T>(
        items: res.items,
        status: status,
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
      final res = await fetchByStatus(current.status, next);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...res.items],
          page: next,
          hasMore: _hasMore(next, res.totalPages, res.items.length),
          isLoadingMore: false,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('LibraryNotifier.loadMore failed: $e\n$stackTrace');
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

class MovieLibraryNotifier extends _LibraryNotifier<Movie> {
  @override
  Future<({List<Movie> items, int totalPages})> fetchByStatus(
    String status,
    int page,
  ) async {
    final res = await ref
        .read(movieServiceProvider)
        .discoverCatalog(page: page, params: {'with_account_status': status});
    return (
      items: res.results.where((m) => m.posterPath.isNotEmpty).toList(),
      totalPages: res.totalPages,
    );
  }
}

class TvLibraryNotifier extends _LibraryNotifier<TvShow> {
  @override
  Future<({List<TvShow> items, int totalPages})> fetchByStatus(
    String status,
    int page,
  ) async {
    final res = await ref
        .read(seriesServiceProvider)
        .discover(page: page, params: {'with_account_status': status});
    return (
      items: res.results.where((s) => s.posterPath.isNotEmpty).toList(),
      totalPages: res.totalPages,
    );
  }
}

final movieLibraryProvider =
    AsyncNotifierProvider<MovieLibraryNotifier, LibraryState<Movie>>(
      MovieLibraryNotifier.new,
    );

final tvLibraryProvider =
    AsyncNotifierProvider<TvLibraryNotifier, LibraryState<TvShow>>(
      TvLibraryNotifier.new,
    );
