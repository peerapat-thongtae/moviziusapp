import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';

String _fmt(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

final releasingTodayProvider = FutureProvider.family<List<Movie>, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(movieServiceProvider);
  final dateStr = _fmt(_normalize(date));
  final response = await service.discoverCatalog(
    params: {
      'release_date.gte': dateStr,
      'release_date.lte': dateStr,
      // 'with_release_type': '3|2',
    },
  );
  return response.results;
});
