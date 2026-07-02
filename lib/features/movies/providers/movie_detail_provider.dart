import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie_discover_response.dart';
import '../services/movie_service.dart';

/// Fetches a single movie's full detail from `GET /movie/:id`. Used by the
/// detail page when it wasn't handed a fully-fetched [Movie] via the route
/// (e.g. deep links, or entry points that only pass an id/title).
final movieDetailProvider = FutureProvider.family<Movie, int>((ref, id) {
  return ref.watch(movieServiceProvider).detail(id);
});
