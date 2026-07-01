class RoutePaths {
  RoutePaths._();

  static const login = '/login';
  static const home = '/';
  static const search = '/search';
  static const explore = '/explore';
  static const profile = '/profile';
  static const movieDetail = '/movie/:id';
  static const seriesDetail = '/series/:id';
  static const continueWatching = '/continue-watching';
  static const calendar = '/calendar';
  static const movieLibrary = '/profile/movies';
  static const tvLibrary = '/profile/tv';

  static const personDetail = '/person/:id';

  static String movieDetailPath(int id) => '/movie/$id';
  static String seriesDetailPath(int id) => '/series/$id';
  static String personDetailPath(int id) => '/person/$id';
}
