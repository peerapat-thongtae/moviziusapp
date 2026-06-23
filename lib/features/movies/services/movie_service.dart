import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
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

  Future<MovieDiscoverResponse> discoverCatalog({int page = 1}) async {
    final response = await _dio.get(
      '/v2/movie/discover',
      queryParameters: {'page': page},
    );
    return MovieDiscoverResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

final movieServiceProvider = Provider<MovieService>(
  (ref) => MovieService(ref.watch(dioProvider)),
);
