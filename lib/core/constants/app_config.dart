import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The single place in the app allowed to read raw `.env` values.
/// Everything else should go through these getters.
class AppConfig {
  AppConfig._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get auth0Domain => _require('AUTH0_DOMAIN');
  static String get auth0ClientId => _require('AUTH0_CLIENT_ID');
  static String get auth0ApiAudience => _require('AUTH0_API_AUDIENCE');
  static String get moviziusApiUrl => _require('MOVIZIUS_API_URL');
  static String get moviziusGoServiceUrl => _require('MOVIZIUS_GO_SERVICE_URL');
  static String get tmdbApiUrl => _require('TMDB_API_URL');
  static String get tmdbApiKey => _require('TMDB_API_KEY');
  static String get tmdbApiV4Key => _require('TMDB_API_V4_KEY');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required .env key: $key');
    }
    return value;
  }
}
