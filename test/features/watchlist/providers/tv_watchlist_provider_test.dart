import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moviziusapp/features/watchlist/models/tv_watchlist_item.dart';
import 'package:moviziusapp/features/watchlist/providers/tv_watchlist_provider.dart';
import 'package:moviziusapp/features/watchlist/repositories/tv_watchlist_repository.dart';

class _MockRepository extends Mock implements TvWatchlistRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.markEpisodesWatched(any(), any()),
    ).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        tvWatchlistRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> seed(
    ProviderContainer container,
    List<TvWatchlistItem> items,
  ) async {
    when(() => repository.fetchAll()).thenAnswer((_) async => items);
    await container.read(tvWatchlistNotifierProvider.notifier).refresh();
  }

  group('markEpisodeWatched', () {
    test('optimistically appends an EpisodeWatched to the show', () async {
      final container = makeContainer();
      await seed(container, const [TvWatchlistItem(id: 1396, name: 'Show')]);

      await container.read(tvWatchlistNotifierProvider.notifier).markEpisodeWatched(
        showId: 1396,
        episodeId: 62085,
        seasonNumber: 1,
        episodeNumber: 1,
      );

      final item = container.read(tvWatchlistNotifierProvider).value![1396]!;
      expect(item.name, 'Show'); // other fields preserved via copyWith
      expect(item.episodeWatched, hasLength(1));
      expect(item.episodeWatched.single.episodeId, 62085);
      expect(item.episodeWatched.single.seasonNumber, 1);
      expect(item.episodeWatched.single.episodeNumber, 1);
    });

    test('is idempotent for an already-watched episode', () async {
      final container = makeContainer();
      await seed(container, const [TvWatchlistItem(id: 1396)]);
      final notifier = container.read(tvWatchlistNotifierProvider.notifier);

      await notifier.markEpisodeWatched(
        showId: 1396,
        episodeId: 62085,
        seasonNumber: 1,
        episodeNumber: 1,
      );
      await notifier.markEpisodeWatched(
        showId: 1396,
        episodeId: 62085,
        seasonNumber: 1,
        episodeNumber: 1,
      );

      final item = container.read(tvWatchlistNotifierProvider).value![1396]!;
      expect(item.episodeWatched, hasLength(1));
    });
  });
}
