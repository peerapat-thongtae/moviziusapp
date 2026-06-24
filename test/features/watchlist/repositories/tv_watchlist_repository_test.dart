import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/features/watchlist/repositories/tv_watchlist_repository.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late TvWatchlistRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = TvWatchlistRepository(dio);
  });

  group('markEpisodesWatched', () {
    test('POSTs to /tv/episodes with the expected body shape', () async {
      when(
        () => dio.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/tv/episodes'),
          data: const {},
        ),
      );

      await repository.markEpisodesWatched(
        1396,
        [(seasonNumber: 1, episodeNumber: 2)],
      );

      verify(
        () => dio.post(
          '/tv/episodes',
          data: {
            'id': 1396,
            'episodes': [
              {'season_number': 1, 'episode_number': 2},
            ],
          },
        ),
      ).called(1);
    });
  });
}
