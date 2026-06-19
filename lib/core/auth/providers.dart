import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';
import 'auth_repository.dart';

final auth0ClientProvider = Provider<Auth0>((ref) {
  return Auth0(AppConfig.auth0Domain, AppConfig.auth0ClientId);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return Auth0AuthRepository(ref.watch(auth0ClientProvider));
});
