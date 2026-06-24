import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/features/series/models/tv_discover_response.dart';
import 'package:moviziusapp/features/series/providers/continue_watching_provider.dart';
import 'package:moviziusapp/features/series/services/series_service.dart';

class _MockSeriesService extends Mock implements SeriesService {}

TvDiscoverResponse _response(List<Map<String, dynamic>> results) {
  return TvDiscoverResponse.fromJson({
    'page': 1,
    'total_pages': 1,
    'total_results': results.length,
    'results': results,
  });
}

void main() {
  late _MockSeriesService service;

  setUp(() {
    service = _MockSeriesService();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [seriesServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('requests the "watching" status feed and keeps poster-bearing shows',
      () async {
    when(() => service.paginate(any(), page: any(named: 'page'))).thenAnswer(
      (_) async => _response([
        {'id': 1, 'name': 'With Poster', 'poster_path': '/a.jpg'},
        {'id': 2, 'name': 'No Poster', 'poster_path': ''},
      ]),
    );

    final container = makeContainer();
    final shows = await container.read(continueWatchingProvider.future);

    verify(() => service.paginate('watching')).called(1);
    expect(shows, hasLength(1));
    expect(shows.single.id, 1);
  });
}
