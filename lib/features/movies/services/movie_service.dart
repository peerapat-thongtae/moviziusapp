import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviziusapp/core/network/go_service_dio_provider.dart';

import '../models/movie_discover_response.dart';

class MovieService {
  const MovieService(this._dio);

  final Dio _dio;

  Future<MovieDiscoverResponse> discover({int page = 1}) async {
    final response = await _dio.get(
      '/v2/movie/random',
      queryParameters: {
        'page': page,
        'without_status': 'watchlist,watched',
        'total': 15,
      },
    );
    return MovieDiscoverResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Discover/search movies. [params] carries TMDB-style discover query params
  /// (e.g. `sort_by`, `with_genres`, `primary_release_year`, `vote_average.gte`,
  /// `with_text_query`) and is merged alongside [page].
  Future<MovieDiscoverResponse> discoverCatalog({
    int page = 1,
    Map<String, dynamic>? params,
  }) async {
    final response = await _dio.get(
      '/movie/discover',
      queryParameters: {'page': page, ...?params},
    );
    return MovieDiscoverResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

final movieServiceProvider = Provider<MovieService>(
  (ref) => MovieService(ref.watch(goServiceDioProvider)),
);
