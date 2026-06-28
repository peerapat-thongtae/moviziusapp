import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';

String _fmt(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

final airingTodayProvider =
    FutureProvider.family<List<TvShow>, DateTime>((ref, date) async {
  final service = ref.watch(seriesServiceProvider);
  final dateStr = _fmt(_normalize(date));
  final response = await service.discover(params: {
    'with_next_episode_air_date.gte': dateStr,
    'with_next_episode_air_date.lte': dateStr,
  });
  return response.results;
});
