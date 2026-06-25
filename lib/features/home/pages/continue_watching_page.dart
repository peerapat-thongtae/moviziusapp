import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/media_poster_card.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/providers/continue_watching_list_provider.dart';
import '../../series/tv_watch_progress.dart';
import '../../watchlist/providers/tv_watchlist_provider.dart';

/// Full, paginated list of the user's in-progress TV series, opened from the
/// home "Continue Watching" rail's "See all" button. Infinite-scrolls through
/// `GET /v2/tv/paginate/watching`.
class ContinueWatchingPage extends ConsumerStatefulWidget {
  const ContinueWatchingPage({super.key});

  @override
  ConsumerState<ContinueWatchingPage> createState() =>
      _ContinueWatchingPageState();
}

class _ContinueWatchingPageState extends ConsumerState<ContinueWatchingPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(continueWatchingListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(continueWatchingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Continue Watching')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.error_outline,
          text: 'Could not load your shows.',
          onRetry: () => ref.invalidate(continueWatchingListProvider),
        ),
        data: (list) {
          if (list.items.isEmpty) {
            return const _Message(
              icon: Icons.playlist_play_rounded,
              text: 'Nothing in progress yet.',
            );
          }
          return Stack(
            children: [
              GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  list.isLoadingMore ? 24 + 56 : 24,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: list.items.length,
                itemBuilder: (context, index) =>
                    _WatchingGridCard(show: list.items[index]),
              ),
              if (list.isLoadingMore)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Adapts a [TvShow] from the paginate feed into a [MediaPosterCard], pulling
/// the watched count from the watchlist notifier (same logic as the home
/// rail card).
class _WatchingGridCard extends ConsumerWidget {
  const _WatchingGridCard({required this.show});

  final TvShow show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = tvWatchProgress(
      ref.watch(tvWatchlistNotifierProvider).value?[show.id],
      show,
    );

    return MediaPosterCard(
      posterPath: show.posterPath,
      title: show.name,
      progress: progress.fraction,
      trailingText: '${progress.watched}/${progress.total} ep',
      onTap: () => context.push(
        RoutePaths.seriesDetailPath(show.id),
        extra: show,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
