import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tv_watchlist_item.dart';
import '../providers/tv_watchlist_provider.dart';
import '../providers/watchlist_provider.dart';

enum _WatchlistAction { watchlist, watched, remove }

/// Bookmark/eye toggle backed by [watchlistNotifierProvider], reused by the
/// movie and series detail pages. Reflects the item's `accountStatus`:
/// unset -> outlined bookmark, `watchlist` -> filled amber bookmark,
/// `watched` -> amber eye. Tapping opens a sheet to change the status
/// instead of toggling directly, since there are now three states to choose
/// between rather than a simple on/off.
class WatchlistIconButton extends ConsumerWidget {
  const WatchlistIconButton({
    super.key,
    required this.id,
    this.mediaType = 'movie',
  });

  final int id;
  final String mediaType;

  bool get _isTv => mediaType == 'tv';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? status;
    TvWatchlistItem? tvItem;
    if (_isTv) {
      tvItem = ref.watch(tvWatchlistNotifierProvider).value?[id];
      status = tvItem?.accountStatus;
    } else {
      status = ref.watch(watchlistNotifierProvider).value?[id]?.accountStatus;
    }
    final isWatched = status == 'watched';
    final isWatchlisted = status == 'watchlist';
    final isWatching = status == 'watching';
    final isWaitingNextSeason = status == 'waiting_next_season';

    final Widget icon;
    if (isWatching) {
      icon = _WatchingProgressIcon(item: tvItem);
    } else if (isWaitingNextSeason) {
      icon = const Icon(Icons.hourglass_top, color: Colors.amber);
    } else if (isWatched) {
      icon = const Icon(Icons.visibility, color: Colors.amber);
    } else if (isWatchlisted) {
      icon = const Icon(Icons.bookmark, color: Colors.amber);
    } else {
      icon = const Icon(Icons.bookmark_border);
    }

    return IconButton(
      icon: icon,
      tooltip: 'Change watchlist status',
      onPressed: () => _showStatusSheet(context, ref, status),
    );
  }

  Future<void> _showStatusSheet(
    BuildContext context,
    WidgetRef ref,
    String? status,
  ) async {
    final action = await showModalBottomSheet<_WatchlistAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.bookmark,
                color: status == 'watchlist' ? Colors.amber : null,
              ),
              title: const Text('Watchlist'),
              selected: status == 'watchlist',
              onTap: () => Navigator.pop(context, _WatchlistAction.watchlist),
            ),
            ListTile(
              leading: Icon(
                Icons.visibility,
                color: status == 'watched' ? Colors.amber : null,
              ),
              title: const Text('Watched'),
              selected: status == 'watched',
              onTap: () => Navigator.pop(context, _WatchlistAction.watched),
            ),
            if (status == 'watchlist' || status == 'watched')
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Remove'),
                onTap: () => Navigator.pop(context, _WatchlistAction.remove),
              ),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;
    await _applyAction(context, ref, action);
  }

  Future<void> _applyAction(
    BuildContext context,
    WidgetRef ref,
    _WatchlistAction action,
  ) async {
    try {
      if (_isTv) {
        final notifier = ref.read(tvWatchlistNotifierProvider.notifier);
        switch (action) {
          case _WatchlistAction.watchlist:
            await notifier.addToWatchlist(id);
          case _WatchlistAction.watched:
            await notifier.markAsWatched(id);
          case _WatchlistAction.remove:
            await notifier.removeFromWatchlist(id);
        }
      } else {
        final notifier = ref.read(watchlistNotifierProvider.notifier);
        switch (action) {
          case _WatchlistAction.watchlist:
            await notifier.addToWatchlist(id, mediaType: mediaType);
          case _WatchlistAction.watched:
            await notifier.markAsWatched(id, mediaType: mediaType);
          case _WatchlistAction.remove:
            await notifier.removeFromWatchlist(id);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update watchlist: $e')));
    }
  }
}

/// Play icon ringed by a progress indicator showing `countWatched /
/// numberOfEpisodes` for a show in the `watching` state. Falls back to an
/// indeterminate ring when the episode total is unknown (0), since a
/// determinate `CircularProgressIndicator` with `value: 0` would render as
/// empty instead of "in progress".
class _WatchingProgressIcon extends StatelessWidget {
  const _WatchingProgressIcon({required this.item});

  final TvWatchlistItem? item;

  @override
  Widget build(BuildContext context) {
    final total = item?.numberOfEpisodes ?? 0;
    final watched = item?.countWatched ?? 0;
    final progress = total > 0 ? (watched / total).clamp(0.0, 1.0) : null;

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: Colors.amber,
            backgroundColor: Colors.amber.withValues(alpha: 0.2),
          ),
          const Icon(Icons.play_arrow, size: 14, color: Colors.amber),
        ],
      ),
    );
  }
}
