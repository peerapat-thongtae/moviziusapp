import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/core/auth/auth_notifier.dart';
import 'package:moviziusapp/core/auth/auth_repository.dart';
import 'package:moviziusapp/core/auth/auth_state.dart';
import 'package:moviziusapp/core/auth/providers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

UserProfile _user() => UserProfile(sub: 'auth0|1', name: 'Jane');

Credentials _credentials(UserProfile user) => Credentials(
      idToken: 'id',
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      scopes: const {'openid'},
      user: user,
      tokenType: 'Bearer',
    );

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build() restores an authenticated session', () async {
    final user = _user();
    when(() => repository.restoreSession())
        .thenAnswer((_) async => AuthAuthenticated(user, _credentials(user)));

    expect(container.read(authNotifierProvider), isA<AuthLoading>());

    await pumpEventQueue();

    expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
  });

  test('build() falls back to unauthenticated', () async {
    when(() => repository.restoreSession())
        .thenAnswer((_) async => const AuthUnauthenticated());

    container.read(authNotifierProvider);
    await pumpEventQueue();

    expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
  });

  test('login() success transitions to AuthAuthenticated', () async {
    when(() => repository.restoreSession())
        .thenAnswer((_) async => const AuthUnauthenticated());
    final user = _user();
    when(() => repository.login())
        .thenAnswer((_) async => AuthAuthenticated(user, _credentials(user)));

    container.read(authNotifierProvider);
    await pumpEventQueue();

    await container.read(authNotifierProvider.notifier).login();

    expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());
  });

  test('login() cancellation stays AuthUnauthenticated', () async {
    when(() => repository.restoreSession())
        .thenAnswer((_) async => const AuthUnauthenticated());
    when(() => repository.login())
        .thenAnswer((_) async => const AuthUnauthenticated());

    container.read(authNotifierProvider);
    await pumpEventQueue();

    await container.read(authNotifierProvider.notifier).login();

    expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
  });

  test('login() failure transitions to AuthError', () async {
    when(() => repository.restoreSession())
        .thenAnswer((_) async => const AuthUnauthenticated());
    when(() => repository.login())
        .thenAnswer((_) async => const AuthError('boom'));

    container.read(authNotifierProvider);
    await pumpEventQueue();

    await container.read(authNotifierProvider.notifier).login();

    expect(container.read(authNotifierProvider), isA<AuthError>());
  });

  test('logout() transitions back to AuthUnauthenticated', () async {
    final user = _user();
    when(() => repository.restoreSession()).thenAnswer(
      (_) async => AuthAuthenticated(user, _credentials(user)),
    );
    when(() => repository.logout())
        .thenAnswer((_) async => const AuthUnauthenticated());

    container.read(authNotifierProvider);
    await pumpEventQueue();

    await container.read(authNotifierProvider.notifier).logout();

    expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
  });
}
