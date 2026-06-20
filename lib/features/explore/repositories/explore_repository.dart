import '../../movies/models/movie_discover_response.dart';
import '../../movies/services/movie_service.dart';
import '../models/explore_media_type.dart';
import '../models/explore_video.dart';
import '../models/explore_videos_page.dart';

const _creators = [
  'Vince Gilligan',
  'Shonda Rhimes',
  'Noah Hawley',
  'Jenji Kohan',
  'Ryan Murphy',
  'Phoebe Waller-Bridge',
  'David Benioff',
  'Issa Rae',
  'Michaela Coel',
  'Tony Gilroy',
];

const _seriesStatuses = ['Returning Series', 'Ended', 'Canceled'];

const _genrePool = [
  'Drama',
  'Thriller',
  'Sci-Fi',
  'Action',
  'Comedy',
  'Horror',
  'Mystery',
  'Crime',
  'Fantasy',
  'Adventure',
];

/// Builds a single mock series entry. Metadata (rating, dates, creator,
/// status) is derived from [seed] so each entry gets distinct-looking mock
/// values without hand-typing every field.
ExploreVideo _series({
  required String id,
  required String youtubeId,
  required String title,
  required int seed,
}) {
  final year = 2017 + seed % 8;
  final month = 1 + seed % 12;
  final day = 1 + seed % 28;
  final totalSeasons = 1 + seed % 6;
  return ExploreVideo(
    id: id,
    youtubeId: youtubeId,
    title: title,
    voteAverage: 5.0 + (seed % 41) / 10,
    voteCount: 500 + seed * 137,
    status: _seriesStatuses[seed % _seriesStatuses.length],
    genres: [
      _genrePool[seed % _genrePool.length],
      _genrePool[(seed + 3) % _genrePool.length],
    ],
    firstAirDate:
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    totalSeasons: totalSeasons,
    totalEpisodes: totalSeasons * (6 + seed % 10),
    creator: _creators[seed % _creators.length],
  );
}

final _mockSeries = [
  _series(
    id: 's1',
    youtubeId: 'LTss4risHbE',
    title: 'From — Season 4',
    seed: 1,
  ),
  _series(
    id: 's2',
    youtubeId: 'YUycK-9m1vQ',
    title: 'Avatar: The Last Airbender — Season 2',
    seed: 2,
  ),
  _series(id: 's3', youtubeId: 'Trp4FbB-Gfw', title: 'The Boroughs', seed: 3),
  _series(
    id: 's4',
    youtubeId: 'VWL1zH2q2Zk',
    title: 'Salish & Jordan Matter',
    seed: 4,
  ),
  _series(id: 's5', youtubeId: 'LM1x8D3uUpI', title: 'Thrash', seed: 5),
  _series(
    id: 's6',
    youtubeId: 'ovqCBHdm4NE',
    title: 'The East Palace',
    seed: 6,
  ),
  _series(id: 's7', youtubeId: 'MJo_J9bHM7I', title: 'The Last House', seed: 7),
  _series(id: 's8', youtubeId: 'fUXGrunDo_4', title: 'Nemesis', seed: 8),
  _series(
    id: 's9',
    youtubeId: 'Z8pes4PRAUQ',
    title: 'Norway: The Dark Horse',
    seed: 9,
  ),
  _series(id: 's10', youtubeId: 'zK4dMBXfdpg', title: 'The Westies', seed: 10),
  _series(
    id: 's11',
    youtubeId: 'ZozrvCiB06Q',
    title: 'Your Friends & Neighbors — Season 2',
    seed: 11,
  ),
  _series(
    id: 's12',
    youtubeId: 'lBmKNJ9i3N4',
    title: 'This Is Not a Murder Mystery',
    seed: 12,
  ),
  _series(
    id: 's13',
    youtubeId: '7Wc6ugY3meg',
    title: 'Crunchyroll — Spring 2026 Season',
    seed: 13,
  ),
  _series(id: 's14', youtubeId: 'zXQ4tyg2cm0', title: 'Killtube', seed: 14),
  _series(id: 's15', youtubeId: 'yBJAEWoEUZ0', title: 'Star City', seed: 15),
  _series(
    id: 's16',
    youtubeId: 'SXiSfXiiOxM',
    title: 'Kaiju No. 8 — Season 2',
    seed: 16,
  ),
];

/// Source of [ExploreVideo] data for the reels feed. Movies come from the
/// real Movizius API via [MovieService] (paginated, see [fetchNextPage]);
/// series are still mock pending a series discover endpoint.
class ExploreRepository {
  ExploreRepository(this._movieService);

  final MovieService _movieService;
  int _moviesPage = 1;
  bool _moviesHasMore = true;

  /// Initial load (or reload) — resets the movies pagination cursor to
  /// page 1.
  Future<ExploreVideosPage> fetchVideos(ExploreMediaType type) async {
    return switch (type) {
      ExploreMediaType.movies => _fetchMoviesPage(reset: true),
      ExploreMediaType.series => ExploreVideosPage(
        videos: _mockSeries,
        hasMore: false,
      ),
    };
  }

  /// Fetches the next page after the last one returned by [fetchVideos] or
  /// this method. Series has no real pagination source, so it's always
  /// reported as having nothing more.
  Future<ExploreVideosPage> fetchNextPage(ExploreMediaType type) async {
    return switch (type) {
      ExploreMediaType.movies => _fetchMoviesPage(reset: false),
      ExploreMediaType.series => const ExploreVideosPage(
        videos: [],
        hasMore: false,
      ),
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
    final videos = response.results.map(_toExploreVideo).nonNulls.toList();
    return ExploreVideosPage(videos: videos, hasMore: _moviesHasMore);
  }

  /// Returns null (and the movie is skipped) if it has no playable YouTube
  /// trailer, since the reels feed has nothing to show without one. `casts`/
  /// `videos`/`releaseDate` are nullable on [Movie] since a discover/list
  /// response may not embed them for every item.
  ExploreVideo? _toExploreVideo(Movie movie) {
    final youtubeId = _trailerKey(movie.videos?.results ?? const []);
    if (youtubeId == null) return null;
    return ExploreVideo(
      id: movie.id.toString(),
      youtubeId: youtubeId,
      title: movie.title,
      voteAverage: movie.voteAverage,
      voteCount: movie.voteCount,
      status: movie.status,
      genres: movie.genres.map((g) => g.name).toList(),
      releaseDate: movie.releaseDate?.toIso8601String().split('T').first ?? '',
      director: _director(movie.casts?.crew ?? const []),
    );
  }

  String? _trailerKey(List<VideosResult> videos) {
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

  String _director(List<Cast> crew) {
    for (final c in crew) {
      if (c.job == 'Director') return c.name;
    }
    return 'Unknown';
  }
}
