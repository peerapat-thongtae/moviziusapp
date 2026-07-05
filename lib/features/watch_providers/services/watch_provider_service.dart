import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/network/tmdb_dio_provider.dart';
import '../models/watch_provider.dart';

/// Fetches the list of TV watch providers straight from TMDB. The movizius-api
/// proxy doesn't expose this endpoint, so it uses [tmdbDioProvider] with the
/// per-request `api_key`, matching [SeriesService.seasonEpisodes].
class WatchProviderService {
  WatchProviderService(this._tmdbDio);

  final Dio _tmdbDio;

  /// `GET /watch/providers/tv` for the Thai (`th`) region, English metadata.
  Future<List<WatchProvider>> tvProviders({
    String language = 'en-US',
    String watchRegion = 'th',
  }) async {
    final response = await _tmdbDio.get(
      '/watch/providers/tv',
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'language': language,
        'watch_region': watchRegion,
      },
    );
    final results = (response.data['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map(WatchProvider.fromJson)
        .toList();
    return results;
  }
}

final watchProviderServiceProvider = Provider<WatchProviderService>(
  (ref) => WatchProviderService(ref.watch(tmdbDioProvider)),
);
