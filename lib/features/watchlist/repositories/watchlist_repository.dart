import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviziusapp/core/network/go_service_dio_provider.dart';

import '../models/watchlist_item.dart';

class WatchlistRepository {
  const WatchlistRepository(this._dio);

  final Dio _dio;

  Future<List<WatchlistItem>> fetchAll() async {
    final response = await _dio.get('/movie/states');
    final data = response.data;
    // Some Movizius list endpoints (e.g. `/v2/movie/random`) wrap their
    // array in `{ results: [...] }` rather than returning a bare array, so
    // accept either shape instead of assuming one.
    final list = switch (data) {
      List() => data,
      {'results': List() && final results} => results,
      _ => throw FormatException(
        'Unexpected /v2/movie response shape: ${data.runtimeType}',
      ),
    };
    return list
        .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setStatus(int id, String status, {double? rating}) {
    return _dio.post(
      '/movie',
      data: {'id': id, 'status': status, 'rating': ?rating},
    );
  }

  Future<void> remove(int id) {
    return _dio.delete('/movie/$id');
  }
}

final watchlistRepositoryProvider = Provider<WatchlistRepository>(
  (ref) => WatchlistRepository(ref.watch(goServiceDioProvider)),
);
