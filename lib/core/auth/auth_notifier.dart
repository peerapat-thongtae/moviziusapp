import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'providers.dart';
import 'user_sync_repository.dart';

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
    final result = await ref.read(authRepositoryProvider).login();
    if (result is AuthAuthenticated) {
      await _syncUser(result.user);
    }
    state = result;
  }

  /// Best-effort: a failed sync must not block the user from getting into
  /// the app, so errors are logged rather than surfaced as an AuthError.
  Future<void> _syncUser(UserProfile user) async {
    try {
      await ref.read(userSyncRepositoryProvider).syncUser(user);
    } catch (e) {
      debugPrint('AuthNotifier: user sync failed: $e');
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    state = await ref.read(authRepositoryProvider).logout();
  }
}
