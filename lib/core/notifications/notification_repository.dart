import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  static const _deviceIdKey = 'device_id';

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  Future<void> registerDevice(String fcmToken, String platform) async {
    final deviceId = await _getOrCreateDeviceId();
    await _dio.post(
      'notification/devices',
      data: {
        'fcm_token': fcmToken,
        'platform': platform,
        'device_id': deviceId,
      },
    );
  }
}
