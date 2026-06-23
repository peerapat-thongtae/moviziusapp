import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/tv_discover_response.dart';

class SeriesService {
  const SeriesService(this._dio);

  final Dio _dio;

  Future<TvDiscoverResponse> discover({int page = 1}) async {
    final response = await _dio.get(
      '/v2/tv/discover',
      queryParameters: {'page': page},
    );
    return TvDiscoverResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

final seriesServiceProvider = Provider<SeriesService>(
  (ref) => SeriesService(ref.watch(dioProvider)),
);
