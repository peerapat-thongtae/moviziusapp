enum HeroMediaType { movie, tv }

/// Unified view of a [Movie] or [TvShow] for the home hero slider, so the
/// widget doesn't need to branch on the source model's shape.
class HeroItem {
  final int id;
  final HeroMediaType mediaType;
  final String title;
  final String posterPath;
  final String overview;
  final double voteAverage;

  /// The original `Movie` or `TvShow` this item was built from, carried
  /// along so the detail page can render full info without a refetch.
  final Object media;

  HeroItem({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.media,
  });
}
