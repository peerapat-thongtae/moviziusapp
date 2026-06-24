import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';

/// Dio client targeting TMDB directly, for endpoints the movizius-api proxy
/// doesn't expose yet (e.g. season/episode detail). Auth is a per-request
/// `api_key` query param, not the app's own Auth0 bearer token, so this
/// intentionally skips [AuthInterceptor].
final tmdbDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.tmdbApiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  return dio;
});
