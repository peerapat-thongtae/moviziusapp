import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tv_watchlist_item.dart';
import '../repositories/tv_watchlist_repository.dart';

/// TV counterpart of `watchlistNotifierProvider`. Holds the signed-in user's
/// TV watchlist keyed by show id, so widgets like [WatchlistIconButton] can
/// look up a show's `accountStatus` in O(1).
final tvWatchlistNotifierProvider =
    AsyncNotifierProvider<TvWatchlistNotifier, Map<int, TvWatchlistItem>>(
      TvWatchlistNotifier.new,
    );

class TvWatchlistNotifier extends AsyncNotifier<Map<int, TvWatchlistItem>> {
  @override
  Future<Map<int, TvWatchlistItem>> build() async {
    final items = await ref.read(tvWatchlistRepositoryProvider).fetchAll();
    return {for (final item in items) item.id: item};
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await ref.read(tvWatchlistRepositoryProvider).fetchAll();
      return {for (final item in items) item.id: item};
    });
    if (state.hasError) {
      debugPrint(
        'TvWatchlistNotifier.refresh failed: ${state.error}\n${state.stackTrace}',
      );
    }
  }

  Future<void> addToWatchlist(int id) async {
    await ref.read(tvWatchlistRepositoryProvider).setStatus(id, 'watchlist');
    final current = Map<int, TvWatchlistItem>.of(state.value ?? {});
    final existing = current[id];
    current[id] = TvWatchlistItem(
      id: id,
      name: existing?.name ?? '',
      accountStatus: 'watchlist',
      watchlistedAt: existing?.watchlistedAt ?? DateTime.now(),
    );
    state = AsyncData(current);
  }

  Future<void> markAsWatched(int id) async {
    await ref.read(tvWatchlistRepositoryProvider).setStatus(id, 'watched');
    final current = Map<int, TvWatchlistItem>.of(state.value ?? {});
    final existing = current[id];
    current[id] = TvWatchlistItem(
      id: id,
      name: existing?.name ?? '',
      accountStatus: 'watched',
      watchlistedAt: existing?.watchlistedAt,
    );
    state = AsyncData(current);
  }

  /// Marks a single episode of [showId] as watched via `POST /tv/episodes`,
  /// then optimistically appends it to the show's `episodeWatched`. No-ops if
  /// the episode is already recorded (the endpoint is append-only).
  Future<void> markEpisodeWatched({
    required int showId,
    required int episodeId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    await ref.read(tvWatchlistRepositoryProvider).markEpisodesWatched(showId, [
      (
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        episodeId: episodeId,
      ),
    ]);
    final current = Map<int, TvWatchlistItem>.of(state.value ?? {});
    final existing = current[showId];
    if (existing != null &&
        existing.episodeWatched.any((e) => e.episodeId == episodeId)) {
      return;
    }
    final added = EpisodeWatched(
      episodeId: episodeId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      watchedAt: DateTime.now(),
    );
    current[showId] = existing == null
        ? TvWatchlistItem(id: showId, episodeWatched: [added])
        : existing.copyWith(
            episodeWatched: [...existing.episodeWatched, added],
          );
    state = AsyncData(current);
  }

  Future<void> removeFromWatchlist(int id) async {
    await ref.read(tvWatchlistRepositoryProvider).remove(id);
    final current = Map<int, TvWatchlistItem>.of(state.value ?? {});
    current.remove(id);
    state = AsyncData(current);
  }
}
