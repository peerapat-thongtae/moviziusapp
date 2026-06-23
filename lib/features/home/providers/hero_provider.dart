import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../movies/services/movie_service.dart';
import '../../series/services/series_service.dart';
import '../models/hero_item.dart';
import '../repositories/hero_repository.dart';

final heroRepositoryProvider = Provider<HeroRepository>(
  (ref) => HeroRepository(
    ref.watch(movieServiceProvider),
    ref.watch(seriesServiceProvider),
  ),
);

final heroSliderProvider = FutureProvider<List<HeroItem>>(
  (ref) => ref.watch(heroRepositoryProvider).fetchHeroItems(),
);
