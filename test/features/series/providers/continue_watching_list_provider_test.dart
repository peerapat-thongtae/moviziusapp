import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/features/series/models/tv_discover_response.dart';
import 'package:moviziusapp/features/series/providers/continue_watching_list_provider.dart';
import 'package:moviziusapp/features/series/services/series_service.dart';

class _MockSeriesService extends Mock implements SeriesService {}

TvDiscoverResponse _page(
  int page,
  int totalPages,
  List<Map<String, dynamic>> results,
) {
  return TvDiscoverResponse.fromJson({
    'page': page,
    'total_pages': totalPages,
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

  test('build loads page 1 and derives hasMore from total_pages', () async {
    when(() => service.paginate('watching', page: 1)).thenAnswer(
      (_) async => _page(1, 2, [
        {'id': 1, 'name': 'A', 'poster_path': '/a.jpg'},
        {'id': 2, 'name': 'No Poster', 'poster_path': ''},
      ]),
    );

    final container = makeContainer();
    final list = await container.read(continueWatchingListProvider.future);

    expect(list.items.map((s) => s.id), [1]); // poster-less filtered out
    expect(list.page, 1);
    expect(list.hasMore, isTrue);
  });

  test('loadMore requests the next page, appends, and stops at the last page',
      () async {
    when(() => service.paginate('watching', page: 1)).thenAnswer(
      (_) async => _page(1, 2, [
        {'id': 1, 'name': 'A', 'poster_path': '/a.jpg'},
      ]),
    );
    when(() => service.paginate('watching', page: 2)).thenAnswer(
      (_) async => _page(2, 2, [
        {'id': 2, 'name': 'B', 'poster_path': '/b.jpg'},
      ]),
    );

    final container = makeContainer();
    await container.read(continueWatchingListProvider.future);

    await container.read(continueWatchingListProvider.notifier).loadMore();

    final list = container.read(continueWatchingListProvider).value!;
    verify(() => service.paginate('watching', page: 2)).called(1);
    expect(list.items.map((s) => s.id), [1, 2]);
    expect(list.page, 2);
    expect(list.hasMore, isFalse);
    expect(list.isLoadingMore, isFalse);
  });

  test('loadMore is a no-op once hasMore is false', () async {
    when(() => service.paginate('watching', page: 1)).thenAnswer(
      (_) async => _page(1, 1, [
        {'id': 1, 'name': 'A', 'poster_path': '/a.jpg'},
      ]),
    );

    final container = makeContainer();
    await container.read(continueWatchingListProvider.future);

    await container.read(continueWatchingListProvider.notifier).loadMore();

    verifyNever(() => service.paginate('watching', page: 2));
  });
}
