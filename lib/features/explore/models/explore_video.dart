class ExploreVideo {
  final String id;
  final String youtubeId;
  final String title;
  final double voteAverage;
  final int voteCount;
  final String status;
  final List<String> genres;
  final String posterPath;
  final String backdropPath;

  // Movie-only metadata.
  final String? releaseDate;
  final String? director;

  // Series-only metadata.
  final String? firstAirDate;
  final int? totalSeasons;
  final int? totalEpisodes;
  final String? creator;

  const ExploreVideo({
    required this.id,
    required this.youtubeId,
    required this.title,
    required this.voteAverage,
    required this.voteCount,
    required this.status,
    this.genres = const [],
    this.posterPath = '',
    this.backdropPath = '',
    this.releaseDate,
    this.director,
    this.firstAirDate,
    this.totalSeasons,
    this.totalEpisodes,
    this.creator,
  });
}
