import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tv_discover_response.dart';
import '../services/series_service.dart';

/// Fetches a single TV show's full detail from `GET /tv/:id`. Used by the
/// detail page when it wasn't handed a fully-fetched [TvShow] via the route
/// (e.g. deep links, or entry points that only pass an id/title).
final seriesDetailProvider = FutureProvider.family<TvShow, int>((ref, id) {
  return ref.watch(seriesServiceProvider).detail(id);
});
