import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';

/// Attaches the current Auth0 access token as a Bearer header to every
/// request. Uses `credentialsManager.credentials()` - the same call
/// [Auth0AuthRepository] relies on - so refresh is handled by the Auth0 SDK,
/// not duplicated here.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // `connectTimeout`/`receiveTimeout` on the Dio client only bound the
      // actual HTTP call, not time spent here before the request is even
      // dispatched - if credentialsManager.credentials() hangs instead of
      // throwing, the request would otherwise never go out. Bound it
      // explicitly so a hang here can't stall the whole request forever.
      final credentials = await _ref
          .read(auth0ClientProvider)
          .credentialsManager
          .credentials()
          .timeout(const Duration(seconds: 5));
      options.headers['Authorization'] = 'Bearer ${credentials.accessToken}';
    } on CredentialsManagerException catch (e) {
      // No valid session - send unauthenticated; the backend returns 401
      // if the endpoint requires auth. Logged so a silently-missing token
      // is traceable instead of looking like the backend ignored it.
      debugPrint('AuthInterceptor: no valid Auth0 credentials: ${e.message}');
    } catch (e) {
      // Catch-all so an unexpected error still lets the request proceed
      // (without a token) instead of hanging forever waiting on handler.next.
      debugPrint('AuthInterceptor: unexpected error fetching credentials: $e');
    }
    handler.next(options);
  }
}
