import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';
import '../models/hero_item.dart';

/// Fetches the first page of `/v2/movie/trending` and `/v2/tv/trending`
/// (`time_window=day`) in parallel and merges them into a single
/// interleaved (movie, tv, movie, tv, ...) list for the home hero slider.
class HeroRepository {
  HeroRepository(this._movieService, this._seriesService);

  final MovieService _movieService;
  final SeriesService _seriesService;

  Future<List<HeroItem>> fetchHeroItems() async {
    final results = await Future.wait([
      _movieService.trending(page: 1),
      _seriesService.trending(page: 1),
    ]);

    final movies = (results[0] as MovieDiscoverResponse).results
        .where((m) => m.posterPath.isNotEmpty)
        .map(_fromMovie)
        .toList();
    final series = (results[1] as TvDiscoverResponse).results
        .where((s) => s.posterPath.isNotEmpty)
        .map(_fromTv)
        .toList();

    return _interleave(movies, series);
  }

  List<HeroItem> _interleave(List<HeroItem> a, List<HeroItem> b) {
    final merged = <HeroItem>[];
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      if (i < a.length) merged.add(a[i]);
      if (i < b.length) merged.add(b[i]);
    }
    return merged;
  }

  HeroItem _fromMovie(Movie movie) => HeroItem(
    id: movie.id,
    mediaType: HeroMediaType.movie,
    title: movie.title,
    posterPath: movie.posterPath,
    overview: movie.overview,
    voteAverage: movie.voteAverage,
    media: movie,
  );

  HeroItem _fromTv(TvShow show) => HeroItem(
    id: show.id,
    mediaType: HeroMediaType.tv,
    title: show.name,
    posterPath: show.posterPath,
    overview: show.overview,
    voteAverage: show.voteAverage,
    media: show,
  );
}
