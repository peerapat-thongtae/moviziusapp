import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviziusapp/core/auth/auth_notifier.dart';
import 'package:moviziusapp/core/auth/auth_state.dart';
import 'package:moviziusapp/features/auth/pages/login_page.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initialState);

  final AuthState _initialState;
  int loginCallCount = 0;

  @override
  AuthState build() => _initialState;

  @override
  Future<void> login() async {
    loginCallCount++;
  }
}

Widget _wrap(AuthState state, {_FakeAuthNotifier? notifier}) {
  final fake = notifier ?? _FakeAuthNotifier(state);
  return ProviderScope(
    overrides: [authNotifierProvider.overrideWith(() => fake)],
    child: const MaterialApp(home: LoginPage()),
  );
}

void main() {
  testWidgets('shows Log In button when unauthenticated', (tester) async {
    await tester.pumpWidget(_wrap(const AuthUnauthenticated()));

    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a loading spinner instead of the button when loading',
      (tester) async {
    await tester.pumpWidget(_wrap(const AuthLoading()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Log In'), findsNothing);
  });

  testWidgets('shows the error message when AuthError', (tester) async {
    await tester.pumpWidget(_wrap(const AuthError("Couldn't sign in.")));

    expect(find.text("Couldn't sign in."), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('tapping Log In calls notifier.login()', (tester) async {
    final fake = _FakeAuthNotifier(const AuthUnauthenticated());
    await tester.pumpWidget(_wrap(const AuthUnauthenticated(), notifier: fake));

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(fake.loginCallCount, 1);
  });
}
