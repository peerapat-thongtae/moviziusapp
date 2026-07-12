import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/go_service_dio_provider.dart';

class UserSyncRepository {
  const UserSyncRepository(this._dio);

  final Dio _dio;

  Future<void> syncUser(UserProfile user) {
    return _dio.post('/user/sync', data: user.toMap());
  }
}

final userSyncRepositoryProvider = Provider<UserSyncRepository>(
  (ref) => UserSyncRepository(ref.watch(goServiceDioProvider)),
);
