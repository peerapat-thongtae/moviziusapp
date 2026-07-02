import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviziusapp/core/network/go_service_dio_provider.dart';

import '../models/movie_discover_response.dart';

class MovieService {
  const MovieService(this._dio);

  final Dio _dio;

  Future<MovieDiscoverResponse> discover({int page = 1}) async {
    final response = await _dio.get(
      '/movie/random',
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

  /// Full movie detail from `GET /movie/:id`. The proxy returns the same
  /// [Movie] shape as the discover feed (genres, casts, videos, etc.), so it
  /// parses through the same [Movie.fromJson].
  Future<Movie> detail(int id) async {
    final response = await _dio.get('/movie/$id');
    return Movie.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MovieDiscoverResponse> search(String q, {int page = 1}) async {
    final response = await _dio.get(
      '/movie/search',
      queryParameters: {'q': q, 'page': page},
    );
    return MovieDiscoverResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Discover/search movies. [params] carries TMDB-style discover query params
  /// (e.g. `sort_by`, `with_genres`, `primary_release_year`, `vote_average.gte`)
  /// and is merged alongside [page].
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
