import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/media_poster_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../series/models/tv_discover_response.dart';
import '../../series/providers/continue_watching_provider.dart';
import '../../series/tv_watch_progress.dart';
import '../../watchlist/providers/tv_watchlist_provider.dart';

const _cardWidth = 120.0;
const _posterHeight = 180.0;

/// Horizontal rail of TV series the user is partway through, shown under the
/// home hero. Each card carries a progress bar comparing watched vs. total
/// episodes. The whole section hides itself while loading, on error, or when
/// the feed is empty, so the home page never shows a dangling header.
class ContinueWatchingSection extends ConsumerWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shows = ref.watch(continueWatchingProvider);

    return shows.when(
      loading: () => const _ContinueWatchingSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : _Section(shows: items),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.shows});

  final List<TvShow> shows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Continue Watching',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(RoutePaths.continueWatching),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _posterHeight + 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shows.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == shows.length - 1 ? 0 : 12,
                ),
                child: _ContinueWatchingCard(show: shows[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder mirroring [_Section]: a shimmer header bar plus a
/// non-scrolling row of poster-card skeletons reusing the same dimensions.
class _ContinueWatchingSkeleton extends StatelessWidget {
  const _ContinueWatchingSkeleton();

  static const _placeholderCount = 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Skeleton(width: 180, height: 24),
        ),
        SizedBox(
          height: _posterHeight + 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _placeholderCount,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _placeholderCount - 1 ? 0 : 12,
                ),
                child: const SizedBox(
                  width: _cardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: _cardWidth, height: _posterHeight),
                      SizedBox(height: 8),
                      Skeleton(width: 90, height: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContinueWatchingCard extends ConsumerWidget {
  const _ContinueWatchingCard({required this.show});

  final TvShow show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = tvWatchProgress(
      ref.watch(tvWatchlistNotifierProvider).value?[show.id],
      show,
    );

    return SizedBox(
      width: _cardWidth,
      child: MediaPosterCard(
        posterPath: show.posterPath,
        title: show.name,
        progress: progress.fraction,
        trailingText: '${progress.watched}/${progress.total} ep',
        onTap: () => context.push(
          RoutePaths.seriesDetailPath(show.id),
          extra: show,
        ),
      ),
    );
  }
}
