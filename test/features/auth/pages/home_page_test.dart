import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviziusapp/core/auth/auth_notifier.dart';
import 'package:moviziusapp/core/auth/auth_state.dart';
import 'package:moviziusapp/features/auth/pages/home_page.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;
  int logoutCallCount = 0;

  @override
  AuthState build() => _initialState;

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }
}

UserProfile _user({String? name, String? email}) =>
    UserProfile(sub: 'auth0|1', name: name, email: email);

Credentials _credentials(UserProfile user) => Credentials(
      idToken: 'id',
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      scopes: const {'openid'},
      user: user,
      tokenType: 'Bearer',
    );

Widget _wrap(AuthState state, {_FakeAuthNotifier? notifier}) {
  final fake = notifier ?? _FakeAuthNotifier(state);
  return ProviderScope(
    overrides: [authNotifierProvider.overrideWith(() => fake)],
    child: const MaterialApp(home: HomePage()),
  );
}

void main() {
  testWidgets('shows the user name when authenticated', (tester) async {
    final user = _user(name: 'Jane Doe');
    await tester.pumpWidget(
      _wrap(AuthAuthenticated(user, _credentials(user))),
    );

    expect(find.text('Welcome, Jane Doe'), findsOneWidget);
  });

  testWidgets('falls back to email when name is missing', (tester) async {
    final user = _user(email: 'jane@example.com');
    await tester.pumpWidget(
      _wrap(AuthAuthenticated(user, _credentials(user))),
    );

    expect(find.text('Welcome, jane@example.com'), findsOneWidget);
  });

  testWidgets('tapping logout calls notifier.logout()', (tester) async {
    final user = _user(name: 'Jane Doe');
    final fake = _FakeAuthNotifier(AuthAuthenticated(user, _credentials(user)));
    await tester.pumpWidget(
      _wrap(AuthAuthenticated(user, _credentials(user)), notifier: fake),
    );

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(fake.logoutCallCount, 1);
  });
}
