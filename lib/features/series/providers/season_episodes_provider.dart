import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tv_discover_response.dart';
import '../services/series_service.dart';

final seasonEpisodesProvider = FutureProvider.family<
    List<Episode>, ({int seriesId, int seasonNumber})>((ref, key) {
  return ref
      .watch(seriesServiceProvider)
      .seasonEpisodes(key.seriesId, key.seasonNumber);
});
