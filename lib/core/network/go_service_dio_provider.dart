import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';
import 'auth_interceptor.dart';

final goServiceDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.moviziusGoServiceUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LogInterceptor(requestBody: false, responseBody: false),
  ]);
  return dio;
});
