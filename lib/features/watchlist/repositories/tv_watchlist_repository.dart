import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviziusapp/core/network/go_service_dio_provider.dart';

import '../models/tv_watchlist_item.dart';

/// TV counterpart of [WatchlistRepository], talking to `/v2/tv` instead of
/// `/v2/movie`. Kept as a sibling class (rather than parameterising the movie
/// repo) so the two media types can diverge — TV carries richer per-item data
/// (episodes/seasons) than movies.
class TvWatchlistRepository {
  const TvWatchlistRepository(this._dio);

  final Dio _dio;

  Future<List<TvWatchlistItem>> fetchAll() async {
    final response = await _dio.get('/tv/states');
    final data = response.data;
    // Accept either a bare array or a `{ results: [...] }` wrapper, matching
    // the movie endpoint's tolerance for both shapes.
    final list = switch (data) {
      List() => data,
      {'results': List() && final results} => results,
      _ => throw FormatException(
        'Unexpected /v2/tv response shape: ${data.runtimeType}',
      ),
    };
    return list
        .map((e) => TvWatchlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setStatus(int id, String status, {double? rating}) {
    return _dio.post(
      '/tv',
      data: {'id': id, 'status': status, 'rating': ?rating},
    );
  }

  Future<void> remove(int id) {
    return _dio.delete('/tv/$id');
  }

  /// Marks one or more episodes of show [id] as watched. Append-only: the API
  /// has no un-watch counterpart yet, so episodes can only be added.
  Future<void> markEpisodesWatched(
    int id,
    List<({int seasonNumber, int episodeNumber, int episodeId})> episodes,
  ) {
    return _dio.post(
      '/tv/episodes',
      data: {
        'id': id,
        'episodes': [
          for (final e in episodes)
            {
              'season_number': e.seasonNumber,
              'episode_number': e.episodeNumber,
              'episode_id': e.episodeId,
            },
        ],
      },
    );
  }
}

final tvWatchlistRepositoryProvider = Provider<TvWatchlistRepository>(
  (ref) => TvWatchlistRepository(ref.watch(goServiceDioProvider)),
);
