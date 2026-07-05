import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watch_provider.dart';
import '../services/watch_provider_service.dart';

/// Persists the TV watch-provider configuration in SharedPreferences so future
/// features can read it without hitting the network. The config is plain public
/// TMDB metadata (no tokens), so SharedPreferences is the right store per the
/// project's local-storage rules.
class WatchProviderRepository {
  WatchProviderRepository(this._service);

  final WatchProviderService _service;

  static const _configKey = 'tv_watch_providers';

  /// Fetches the latest TV watch providers from TMDB and caches them locally.
  /// Called once on app start; failures are swallowed so a flaky network never
  /// blocks launch — the previously cached config (if any) stays in place.
  Future<void> refreshTvProviders() async {
    final providers = await _service.tvProviders();
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(providers.map((p) => p.toJson()).toList());
    await prefs.setString(_configKey, encoded);
  }

  /// Reads the cached TV watch-provider configuration, or an empty list when
  /// nothing has been stored yet.
  Future<List<WatchProvider>> cachedTvProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(WatchProvider.fromJson)
        .toList();
  }
}

final watchProviderRepositoryProvider = Provider<WatchProviderRepository>(
  (ref) => WatchProviderRepository(ref.watch(watchProviderServiceProvider)),
);

/// Reads the locally cached TV watch-provider configuration. Future features
/// (filters, badges) can `ref.watch` this instead of re-fetching from TMDB.
final tvWatchProvidersProvider = FutureProvider<List<WatchProvider>>(
  (ref) => ref.watch(watchProviderRepositoryProvider).cachedTvProviders(),
);
