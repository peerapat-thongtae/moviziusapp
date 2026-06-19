import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/core/auth/auth_repository.dart';
import 'package:moviziusapp/core/auth/auth_state.dart';

class _MockCredentialsManager extends Mock implements CredentialsManager {}

void main() {
  late _MockCredentialsManager credentialsManager;
  late Auth0AuthRepository repository;

  setUp(() {
    credentialsManager = _MockCredentialsManager();
    final auth0 = Auth0(
      'tenant.auth0.com',
      'client_id',
      credentialsManager: credentialsManager,
    );
    repository = Auth0AuthRepository(auth0);
  });

  group('restoreSession', () {
    test('returns AuthUnauthenticated when no valid credentials', () async {
      when(() => credentialsManager.hasValidCredentials())
          .thenAnswer((_) async => false);

      final result = await repository.restoreSession();

      expect(result, isA<AuthUnauthenticated>());
    });

    test('returns AuthAuthenticated when valid credentials exist', () async {
      final user = UserProfile(sub: 'auth0|123', name: 'Jane Doe');
      final credentials = Credentials(
        idToken: 'id',
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        scopes: const {'openid'},
        user: user,
        tokenType: 'Bearer',
      );
      when(() => credentialsManager.hasValidCredentials())
          .thenAnswer((_) async => true);
      when(() => credentialsManager.credentials())
          .thenAnswer((_) async => credentials);

      final result = await repository.restoreSession();

      expect(result, isA<AuthAuthenticated>());
      expect((result as AuthAuthenticated).user.name, 'Jane Doe');
    });

    test('returns AuthUnauthenticated when CredentialsManagerException is thrown',
        () async {
      when(() => credentialsManager.hasValidCredentials())
          .thenAnswer((_) async => true);
      when(() => credentialsManager.credentials()).thenThrow(
        const CredentialsManagerException(
          'NO_REFRESH_TOKEN',
          'no refresh token',
          {},
        ),
      );

      final result = await repository.restoreSession();

      expect(result, isA<AuthUnauthenticated>());
    });
  });

  group('mapLoginException', () {
    test('maps user-cancelled to AuthUnauthenticated', () {
      const exception = WebAuthenticationException(
        'USER_CANCELLED',
        'cancelled',
        {},
      );

      final result = repository.mapLoginException(exception);

      expect(result, isA<AuthUnauthenticated>());
    });

    test('maps other failures to AuthError', () {
      const exception = WebAuthenticationException(
        'a0.network_error',
        'network error',
        {},
      );

      final result = repository.mapLoginException(exception);

      expect(result, isA<AuthError>());
    });
  });

  group('mapLogoutException', () {
    test('maps failures to AuthError', () {
      const exception = WebAuthenticationException('unknown', 'failed', {});

      final result = repository.mapLogoutException(exception);

      expect(result, isA<AuthError>());
    });
  });
}
