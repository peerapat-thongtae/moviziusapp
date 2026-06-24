import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tv_discover_response.dart';
import '../services/series_service.dart';

/// TV series the user is partway through, powering the home "Continue
/// Watching" rail. Backed by `GET /v2/tv/paginate/watching`. Poster-less
/// shows are dropped since the rail is purely poster cards.
final continueWatchingProvider = FutureProvider<List<TvShow>>((ref) async {
  final res = await ref.watch(seriesServiceProvider).paginate('watching');
  return res.results.where((s) => s.posterPath.isNotEmpty).toList();
});
