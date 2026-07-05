import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/services/series_service.dart';
import '../models/explore_media_type.dart';
import '../models/explore_video.dart';
import '../models/explore_videos_page.dart';

/// Source of [ExploreVideo] data for the reels feed. Both movies and series
/// come from the real Movizius API (paginated, see [fetchNextPage]).
class ExploreRepository {
  ExploreRepository(this._movieService, this._seriesService);

  final MovieService _movieService;
  final SeriesService _seriesService;
  int _moviesPage = 1;
  bool _moviesHasMore = true;
  int _seriesPage = 1;
  bool _seriesHasMore = true;

  /// Initial load (or reload) — resets the pagination cursor for [type] to
  /// page 1.
  Future<ExploreVideosPage> fetchVideos(ExploreMediaType type) async {
    return switch (type) {
      ExploreMediaType.movies => _fetchMoviesPage(reset: true),
      ExploreMediaType.series => _fetchSeriesPage(reset: true),
    };
  }

  /// Fetches the next page after the last one returned by [fetchVideos] or
  /// this method.
  Future<ExploreVideosPage> fetchNextPage(ExploreMediaType type) async {
    return switch (type) {
      ExploreMediaType.movies => _fetchMoviesPage(reset: false),
      ExploreMediaType.series => _fetchSeriesPage(reset: false),
    };
  }

  Future<ExploreVideosPage> _fetchMoviesPage({required bool reset}) async {
    if (reset) {
      _moviesPage = 1;
      _moviesHasMore = true;
    } else if (!_moviesHasMore) {
      return const ExploreVideosPage(videos: [], hasMore: false);
    } else {
      _moviesPage++;
    }

    final response = await _movieService.discover(page: _moviesPage);
    // `/v2/movie/random` has no real "total pages" concept (totalPages
    // defaults to 0 when absent from the response), so infer hasMore from
    // whether this batch actually returned anything instead. Checked against
    // the raw batch, not the post-filter list below, so a batch that happens
    // to have zero usable trailers doesn't permanently stop pagination.
    _moviesHasMore = response.results.isNotEmpty;
    final videos = response.results
        .map(_toExploreVideoFromMovie)
        .nonNulls
        .toList();
    return ExploreVideosPage(videos: videos, hasMore: _moviesHasMore);
  }

  Future<ExploreVideosPage> _fetchSeriesPage({required bool reset}) async {
    if (reset) {
      _seriesPage = 1;
      _seriesHasMore = true;
    } else if (!_seriesHasMore) {
      return const ExploreVideosPage(videos: [], hasMore: false);
    } else {
      _seriesPage++;
    }

    final response = await _seriesService.random(page: _seriesPage);
    // Same `/v2/tv/random` "no total pages" caveat as movies above.
    _seriesHasMore = response.results.isNotEmpty;
    final videos = response.results
        .map(_toExploreVideoFromSeries)
        .nonNulls
        .toList();
    return ExploreVideosPage(videos: videos, hasMore: _seriesHasMore);
  }

  /// Returns null (and the movie is skipped) if it has no playable YouTube
  /// trailer, since the reels feed has nothing to show without one. `casts`/
  /// `videos`/`releaseDate` are nullable on [Movie] since a discover/list
  /// response may not embed them for every item.
  ExploreVideo? _toExploreVideoFromMovie(Movie movie) {
    final youtubeId = _movieTrailerKey(movie.videos?.results ?? const []);
    if (youtubeId == null) return null;
    return ExploreVideo(
      id: movie.id.toString(),
      youtubeId: youtubeId,
      title: movie.title,
      voteAverage: movie.voteAverage,
      voteCount: movie.voteCount,
      status: movie.status,
      genres: movie.genres.map((g) => g.name).toList(),
      releaseDate:
          movie.effectiveReleaseDate?.toIso8601String().split('T').first ??
          '',
      director: movie.director ?? 'Unknown',
    );
  }

  /// Same trailer-required skip rule as [_toExploreVideoFromMovie].
  ExploreVideo? _toExploreVideoFromSeries(TvShow series) {
    final youtubeId = _seriesTrailerKey(series.videos?.results ?? const []);
    if (youtubeId == null) return null;
    return ExploreVideo(
      id: series.id.toString(),
      youtubeId: youtubeId,
      title: series.name,
      voteAverage: series.voteAverage,
      voteCount: series.voteCount,
      status: series.status,
      genres: series.genres.map((g) => g.name).toList(),
      firstAirDate: series.firstAirDate,
      totalSeasons: series.numberOfSeasons,
      totalEpisodes: series.numberOfEpisodes,
      creator: series.creator ?? 'Unknown',
    );
  }

  String? _movieTrailerKey(List<VideosResult> videos) {
    for (final v in videos) {
      if (v.site == Site.YOU_TUBE &&
          v.type == VideoType.TRAILER &&
          v.official) {
        return v.key;
      }
    }
    for (final v in videos) {
      if (v.site == Site.YOU_TUBE) return v.key;
    }
    return null;
  }

  String? _seriesTrailerKey(List<SeriesVideoResult> videos) {
    for (final v in videos) {
      if (v.site == 'YouTube' && v.type == 'Trailer' && v.official) {
        return v.key;
      }
    }
    for (final v in videos) {
      if (v.site == 'YouTube') return v.key;
    }
    return null;
  }
}
