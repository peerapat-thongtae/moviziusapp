import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_notifier.dart';

/// Bridges Riverpod's [authNotifierProvider] state changes into a
/// [Listenable] GoRouter can use as `refreshListenable`, so route
/// redirection re-runs on login/logout, not just on manual navigation.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) => notifyListeners());
  }
}
