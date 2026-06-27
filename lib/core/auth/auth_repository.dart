import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';
import 'auth_state.dart';

abstract class AuthRepository {
  Future<AuthState> restoreSession();
  Future<AuthState> login();
  Future<AuthState> logout();
}

/// Wraps the Auth0 SDK. Token storage/refresh is handled internally by
/// [Auth0.credentialsManager] (native secure storage) - no separate
/// flutter_secure_storage dependency needed for this.
class Auth0AuthRepository implements AuthRepository {
  Auth0AuthRepository(this._auth0);

  final Auth0 _auth0;

  /// (Android only - ignored on iOS) Must match android/app/build.gradle.kts's
  /// `auth0Scheme` manifest placeholder and the applicationId. Using a custom
  /// scheme instead of "https" avoids depending on Android App Links
  /// verification for the redirect back into the app after login/logout.
  static const _androidScheme = 'com.wbz.movizius';

  @override
  Future<AuthState> restoreSession() async {
    try {
      final hasValid = await _auth0.credentialsManager.hasValidCredentials();
      if (!hasValid) return const AuthUnauthenticated();
      final credentials = await _auth0.credentialsManager.credentials();
      return AuthAuthenticated(credentials.user, credentials);
    } on CredentialsManagerException catch (e) {
      // Expected lifecycle event (refresh token missing/expired/revoked) -
      // treat as logged out, not an error to surface to the user.
      debugPrint('AuthRepository.restoreSession: ${e.message}');
      return const AuthUnauthenticated();
    }
  }

  @override
  Future<AuthState> login() async {
    try {
      final credentials = await _auth0
          .webAuthentication(scheme: _androidScheme)
          .login(audience: AppConfig.auth0ApiAudience);
      return AuthAuthenticated(credentials.user, credentials);
    } on WebAuthenticationException catch (e) {
      return mapLoginException(e);
    }
  }

  @override
  Future<AuthState> logout() async {
    try {
      await _auth0.webAuthentication(scheme: _androidScheme).logout();
      return const AuthUnauthenticated();
    } on WebAuthenticationException catch (e) {
      return mapLogoutException(e);
    }
  }

  /// Extracted so the exception-to-state mapping can be unit tested without
  /// mocking the platform channel behind [WebAuthentication.login].
  @visibleForTesting
  AuthState mapLoginException(WebAuthenticationException e) {
    if (e.isUserCancelledException) return const AuthUnauthenticated();
    debugPrint('AuthRepository.login: ${e.message}');
    return const AuthError("Couldn't sign in. Please try again.");
  }

  @visibleForTesting
  AuthState mapLogoutException(WebAuthenticationException e) {
    debugPrint('AuthRepository.logout: ${e.message}');
    return const AuthError("Couldn't sign out. Please try again.");
  }
}
