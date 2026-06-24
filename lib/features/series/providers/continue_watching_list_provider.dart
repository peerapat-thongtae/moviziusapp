import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tv_discover_response.dart';
import '../services/series_service.dart';

/// Paginated state for the full "Continue Watching" page. Holds the
/// accumulated [items] plus the cursor needed to fetch the next page.
@immutable
class ContinueWatchingList {
  const ContinueWatchingList({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<TvShow> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  ContinueWatchingList copyWith({
    List<TvShow>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ContinueWatchingList(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Infinite-scroll feed of in-progress TV series for the Continue Watching
/// page, paging through `GET /v2/tv/paginate/watching`.
class ContinueWatchingListNotifier extends AsyncNotifier<ContinueWatchingList> {
  static const _status = 'watching';

  @override
  Future<ContinueWatchingList> build() async {
    final res = await ref.watch(seriesServiceProvider).paginate(_status);
    return ContinueWatchingList(
      items: _withPosters(res.results),
      page: 1,
      hasMore: _hasMore(res, 1),
    );
  }

  /// Appends the next page. No-ops when there's nothing left or a fetch is
  /// already in flight. Failures are logged and swallowed (the existing list
  /// stays put) — the next scroll attempt can retry.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final next = current.page + 1;
    try {
      final res = await ref
          .read(seriesServiceProvider)
          .paginate(_status, page: next);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ..._withPosters(res.results)],
          page: next,
          hasMore: _hasMore(res, next),
          isLoadingMore: false,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ContinueWatchingListNotifier.loadMore failed: $e\n$stackTrace');
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  List<TvShow> _withPosters(List<TvShow> shows) =>
      shows.where((s) => s.posterPath.isNotEmpty).toList();

  bool _hasMore(TvDiscoverResponse res, int page) =>
      res.totalPages > 0 ? page < res.totalPages : res.results.isNotEmpty;
}

final continueWatchingListProvider =
    AsyncNotifierProvider<ContinueWatchingListNotifier, ContinueWatchingList>(
      ContinueWatchingListNotifier.new,
    );
