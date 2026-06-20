enum ExploreMediaType {
  movies,
  series;

  String get label => switch (this) {
    ExploreMediaType.movies => 'Movies',
    ExploreMediaType.series => 'Series',
  };

  ExploreMediaType get next => switch (this) {
    ExploreMediaType.movies => ExploreMediaType.series,
    ExploreMediaType.series => ExploreMediaType.movies,
  };
}
