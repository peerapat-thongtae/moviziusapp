/// TMDB images are always served from this fixed public CDN domain
/// regardless of API key/environment, so this is a plain constant rather
/// than an `.env`-backed value like the rest of [AppConfig].
class TmdbImage {
  TmdbImage._();

  static const _baseUrl = 'https://image.tmdb.org/t/p';

  static String backdrop(String path, {String size = 'w1280'}) =>
      '$_baseUrl/$size$path';

  static String poster(String path, {String size = 'w780'}) =>
      '$_baseUrl/$size$path';

  static String still(String path, {String size = 'w300'}) =>
      '$_baseUrl/$size$path';

  static String profile(String path, {String size = 'w185'}) =>
      '$_baseUrl/$size$path';

  static String logo(String path, {String size = 'w92'}) =>
      '$_baseUrl/$size$path';
}
