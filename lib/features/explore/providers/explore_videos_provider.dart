import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/services/movie_service.dart';
import '../../series/services/series_service.dart';
import '../models/explore_media_type.dart';
import '../models/explore_videos_page.dart';
import '../repositories/explore_repository.dart';

final exploreRepositoryProvider = Provider<ExploreRepository>(
  (ref) => ExploreRepository(
    ref.watch(movieServiceProvider),
    ref.watch(seriesServiceProvider),
  ),
);

final exploreVideosProvider =
    FutureProvider.family<ExploreVideosPage, ExploreMediaType>((ref, type) {
      return ref.watch(exploreRepositoryProvider).fetchVideos(type);
    });
