import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/features/series/services/series_service.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late _MockDio tmdbDio;
  late SeriesService service;

  setUpAll(() {
    dotenv.loadFromString(envString: 'TMDB_API_KEY=test_key');
  });

  setUp(() {
    dio = _MockDio();
    tmdbDio = _MockDio();
    service = SeriesService(dio, tmdbDio);
  });

  group('seasonEpisodes', () {
    test('parses episodes from the TMDB season-detail response', () async {
      when(
        () => tmdbDio.get(
          '/tv/1396/season/1',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/tv/1396/season/1'),
          data: {
            '_id': 'abc',
            'air_date': '2008-01-20',
            'name': 'Season 1',
            'overview': '',
            'id': 3572,
            'poster_path': '/poster.jpg',
            'season_number': 1,
            'vote_average': 8.3,
            'episodes': [
              {
                'id': 62085,
                'name': 'Pilot',
                'overview': 'A teacher turns to crime.',
                'vote_average': 8.489,
                'vote_count': 513,
                'air_date': '2008-01-20',
                'episode_number': 1,
                'episode_type': 'standard',
                'production_code': '',
                'runtime': 59,
                'season_number': 1,
                'show_id': 1396,
                'still_path': '/still.jpg',
              },
            ],
          },
        ),
      );

      final episodes = await service.seasonEpisodes(1396, 1);

      expect(episodes, hasLength(1));
      expect(episodes.single.id, 62085);
      expect(episodes.single.name, 'Pilot');
      expect(episodes.single.episodeNumber, 1);
      expect(episodes.single.runtime, 59);
      expect(episodes.single.stillPath, '/still.jpg');
    });
  });

  group('paginate', () {
    test('GETs the paginated status feed and parses watch progress', () async {
      when(
        () => dio.get(
          '/v2/tv/paginate/watching',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v2/tv/paginate/watching'),
          data: {
            'page': 1,
            'total_pages': 1,
            'total_results': 1,
            'results': [
              {
                'id': 1396,
                'name': 'Breaking Bad',
                'poster_path': '/poster.jpg',
                'number_of_episodes': 10,
              },
            ],
          },
        ),
      );

      final res = await service.paginate('watching');

      verify(
        () => dio.get(
          '/v2/tv/paginate/watching',
          queryParameters: {'page': 1, 'with_imdb_rating': true},
        ),
      ).called(1);
      expect(res.results, hasLength(1));
      final show = res.results.single;
      expect(show.id, 1396);
      expect(show.name, 'Breaking Bad');
      expect(show.numberOfEpisodes, 10);
    });
  });
}
