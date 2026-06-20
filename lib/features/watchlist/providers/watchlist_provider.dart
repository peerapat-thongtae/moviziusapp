import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watchlist_item.dart';
import '../repositories/watchlist_repository.dart';

final watchlistNotifierProvider =
    AsyncNotifierProvider<WatchlistNotifier, Map<int, WatchlistItem>>(
      WatchlistNotifier.new,
    );

class WatchlistNotifier extends AsyncNotifier<Map<int, WatchlistItem>> {
  @override
  Future<Map<int, WatchlistItem>> build() async => {};

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await ref.read(watchlistRepositoryProvider).fetchAll();
      return {for (final item in items) item.id: item};
    });
    if (state.hasError) {
      debugPrint(
        'WatchlistNotifier.refresh failed: ${state.error}\n${state.stackTrace}',
      );
    }
  }

  Future<void> addToWatchlist(int id, {String mediaType = 'movie'}) async {
    await ref.read(watchlistRepositoryProvider).setStatus(id, 'watchlist');
    final current = Map<int, WatchlistItem>.of(state.value ?? {});
    current[id] = WatchlistItem(
      id: id,
      mediaType: mediaType,
      accountStatus: 'watchlist',
      watchlistedAt: DateTime.now(),
    );
    state = AsyncData(current);
  }

  Future<void> removeFromWatchlist(int id) async {
    await ref.read(watchlistRepositoryProvider).remove(id);
    final current = Map<int, WatchlistItem>.of(state.value ?? {});
    current.remove(id);
    state = AsyncData(current);
  }
}
