import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_repository.dart';

class FcmService {
  FcmService(this._messaging, this._repository);

  final FirebaseMessaging _messaging;
  final NotificationRepository _repository;

  /// Call once at app startup. Requests permission and subscribes to token
  /// rotations for the lifetime of the app.
  Future<void> initialize() async {
    try {
      await _messaging.requestPermission();
      _messaging.onTokenRefresh.listen(_register);
    } catch (e) {
      debugPrint('FcmService: initialize failed (FCM unavailable?): $e');
    }
  }

  /// Fetches the current FCM token and registers it with the backend.
  /// Call this on login and on app start when the user is authenticated.
  Future<void> registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      // getToken() throws if Google Play Services is unavailable (e.g. emulator)
      debugPrint('FcmService: getToken failed (FCM unavailable?): $e');
    }
  }

  Future<void> _register(String token) async {
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    try {
      await _repository.registerDevice(token, platform);
      debugPrint('FcmService: device registered (platform=$platform)');
    } on DioException catch (e) {
      debugPrint(
        'FcmService: registerDevice failed '
        '[${e.response?.statusCode}] '
        '${e.response?.data ?? e.message}',
      );
    } catch (e) {
      debugPrint('FcmService: registerDevice unexpected error: $e');
    }
  }
}
