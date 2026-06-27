import 'package:dio/dio.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<void> registerDevice(String fcmToken, String platform) async {
    await _dio.post(
      'notification/devices',
      data: {'fcm_token': fcmToken, 'platform': platform},
    );
  }
}
