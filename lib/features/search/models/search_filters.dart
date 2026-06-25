/// Which catalog a [SearchFilters] is targeting. Decides the year param key
/// (`primary_release_year` vs `first_air_date_year`) and the genre option list.
enum MediaKind { movie, tv }

/// A named option for a single-select filter control (sort / genre / year).
class FilterOption<T> {
  const FilterOption(this.label, this.value);

  final String label;
  final T value;
}

/// Immutable filter state for a search tab. Maps to the TMDB-style discover
/// query params via [toQueryParams]. Both movie and tv tabs share this shape so
/// their UIs stay symmetric (see CLAUDE.md).
class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.sortBy = 'popularity.desc',
    this.genreId,
    this.year,
    this.minRating,
  });

  /// Free-text keyword, sent as `with_text_query` when non-empty.
  final String query;

  /// TMDB `sort_by` value, e.g. `popularity.desc`.
  final String sortBy;

  /// TMDB `with_genres` id.
  final int? genreId;

  /// Release / first-air year.
  final int? year;

  /// Minimum vote average, sent as `vote_average.gte`.
  final double? minRating;

  SearchFilters copyWith({
    String? query,
    String? sortBy,
    int? genreId,
    bool clearGenre = false,
    int? year,
    bool clearYear = false,
    double? minRating,
    bool clearRating = false,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      year: clearYear ? null : (year ?? this.year),
      minRating: clearRating ? null : (minRating ?? this.minRating),
    );
  }

  /// Builds the TMDB-style discover query-param map for [kind]. Only non-empty
  /// filters are included so unset controls don't constrain the result.
  Map<String, dynamic> toQueryParams(MediaKind kind) {
    final yearKey =
        kind == MediaKind.movie ? 'primary_release_year' : 'first_air_date_year';
    return {
      'sort_by': sortBy,
      if (query.trim().isNotEmpty) 'with_text_query': query.trim(),
      if (genreId != null) 'with_genres': genreId,
      if (year != null) yearKey: year,
      if (minRating != null) 'vote_average.gte': minRating,
    };
  }
}

/// Static option lists for the filter controls. Genre id→name maps are the
/// standard TMDB movie/tv genre lists (no genre endpoint exists in the proxy,
/// so they're hardcoded to keep the dependency/endpoint count low).
class SearchOptions {
  SearchOptions._();

  /// Sort options for [kind]. The "Newest" key differs between catalogs
  /// (`primary_release_date` vs `first_air_date`).
  static List<FilterOption<String>> sortOptionsFor(MediaKind kind) => [
    const FilterOption('Popular', 'popularity.desc'),
    const FilterOption('Top rated', 'vote_average.desc'),
    FilterOption(
      'Newest',
      kind == MediaKind.movie
          ? 'primary_release_date.desc'
          : 'first_air_date.desc',
    ),
  ];

  static const movieGenres = <FilterOption<int>>[
    FilterOption('Action', 28),
    FilterOption('Adventure', 12),
    FilterOption('Animation', 16),
    FilterOption('Comedy', 35),
    FilterOption('Crime', 80),
    FilterOption('Documentary', 99),
    FilterOption('Drama', 18),
    FilterOption('Family', 10751),
    FilterOption('Fantasy', 14),
    FilterOption('History', 36),
    FilterOption('Horror', 27),
    FilterOption('Music', 10402),
    FilterOption('Mystery', 9648),
    FilterOption('Romance', 10749),
    FilterOption('Sci-Fi', 878),
    FilterOption('Thriller', 53),
    FilterOption('War', 10752),
    FilterOption('Western', 37),
  ];

  static const tvGenres = <FilterOption<int>>[
    FilterOption('Action & Adventure', 10759),
    FilterOption('Animation', 16),
    FilterOption('Comedy', 35),
    FilterOption('Crime', 80),
    FilterOption('Documentary', 99),
    FilterOption('Drama', 18),
    FilterOption('Family', 10751),
    FilterOption('Kids', 10762),
    FilterOption('Mystery', 9648),
    FilterOption('News', 10763),
    FilterOption('Reality', 10764),
    FilterOption('Sci-Fi & Fantasy', 10765),
    FilterOption('Soap', 10766),
    FilterOption('Talk', 10767),
    FilterOption('War & Politics', 10768),
    FilterOption('Western', 37),
  ];

  static List<FilterOption<int>> genresFor(MediaKind kind) =>
      kind == MediaKind.movie ? movieGenres : tvGenres;

  /// Recent years for the year filter (current year back ~24 years).
  static List<FilterOption<int>> years() {
    final current = DateTime.now().year;
    return [
      for (var y = current; y >= current - 24; y--)
        FilterOption('$y', y),
    ];
  }

  static const ratingOptions = <FilterOption<double>>[
    FilterOption('5+', 5),
    FilterOption('6+', 6),
    FilterOption('7+', 7),
    FilterOption('8+', 8),
    FilterOption('9+', 9),
  ];
}
