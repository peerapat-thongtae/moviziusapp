import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'providers.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthLoading();
  }

  Future<void> _restore() async {
    state = await ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login() async {
    state = const AuthLoading();
    state = await ref.read(authRepositoryProvider).login();
  }

  Future<void> logout() async {
    state = const AuthLoading();
    state = await ref.read(authRepositoryProvider).logout();
  }
}
