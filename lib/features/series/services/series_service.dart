import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviziusapp/core/network/go_service_dio_provider.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/network/tmdb_dio_provider.dart';
import '../models/tv_discover_response.dart';

class SeriesService {
  SeriesService(this._dio, this._tmdbDio);

  final Dio _dio;
  final Dio _tmdbDio;

  /// Discover/search TV series. [params] carries TMDB-style discover query
  /// params (e.g. `sort_by`, `with_genres`, `first_air_date_year`,
  /// `vote_average.gte`, `with_text_query`) and is merged alongside [page].
  Future<TvDiscoverResponse> discover({
    int page = 1,
    Map<String, dynamic>? params,
  }) async {
    final response = await _dio.get(
      '/tv/discover',
      queryParameters: {'page': page, ...?params},
    );
    return TvDiscoverResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Paginated watchlist feed for a given account [status] (e.g. `watching`),
  /// enriched with IMDb ratings. Reuses the discover response shape; the
  /// per-item `count_watched` drives the home "Continue Watching" progress bar.
  Future<TvDiscoverResponse> paginate(String status, {int page = 1}) async {
    final response = await _dio.get(
      '/tv/discover',
      queryParameters: {
        'page': page,
        'with_account_status': 'watching',
        'sort_by': 'max_watched_ep.desc',
      },
    );
    return TvDiscoverResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// The movizius-api proxy has no season/episode-detail endpoint, so this
  /// calls TMDB directly instead. [Episode.fromJson] already matches TMDB's
  /// season-detail episode shape exactly.
  Future<List<Episode>> seasonEpisodes(int seriesId, int seasonNumber) async {
    final response = await _tmdbDio.get(
      '/tv/$seriesId/season/$seasonNumber',
      queryParameters: {'api_key': AppConfig.tmdbApiKey},
    );
    final episodes = (response.data['episodes'] as List)
        .cast<Map<String, dynamic>>();
    return episodes.map(Episode.fromJson).toList();
  }
}

final seriesServiceProvider = Provider<SeriesService>(
  (ref) => SeriesService(
    ref.watch(goServiceDioProvider),
    ref.watch(tmdbDioProvider),
  ),
);
