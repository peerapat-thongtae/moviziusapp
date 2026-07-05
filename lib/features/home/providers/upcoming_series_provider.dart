import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';

String _fmt(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

/// TV series premiering (first air date) in the next 14 days, sorted by
/// popularity, for the home "Upcoming TV Series" rail.
final upcomingSeriesProvider = FutureProvider<List<TvShow>>((ref) async {
  final service = ref.watch(seriesServiceProvider);
  final today = _normalize(DateTime.now());
  final response = await service.discover(
    params: {
      'sort_by': 'popularity.desc',
      'first_air_date.gte': _fmt(today),
      'first_air_date.lte': _fmt(today.add(const Duration(days: 14))),
    },
  );
  return response.results;
});
