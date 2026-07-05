import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';

String _fmt(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

/// Movies releasing in the next 14 days, sorted by popularity, for the home
/// "Upcoming Movies" rail.
final upcomingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final service = ref.watch(movieServiceProvider);
  final today = _normalize(DateTime.now());
  final response = await service.discoverCatalog(
    params: {
      'sort_by': 'popularity.desc',
      'release_date.gte': _fmt(today),
      'release_date.lte': _fmt(today.add(const Duration(days: 14))),
    },
  );
  return response.results;
});
