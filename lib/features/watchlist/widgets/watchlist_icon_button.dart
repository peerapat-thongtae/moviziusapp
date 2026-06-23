import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/watchlist_provider.dart';

enum _WatchlistAction { watchlist, watched, remove }

/// Bookmark/eye toggle backed by [watchlistNotifierProvider], reused by the
/// movie and series detail pages. Reflects the item's `accountStatus`:
/// unset -> outlined bookmark, `watchlist` -> filled amber bookmark,
/// `watched` -> amber eye. Tapping opens a sheet to change the status
/// instead of toggling directly, since there are now three states to choose
/// between rather than a simple on/off.
class WatchlistIconButton extends ConsumerWidget {
  const WatchlistIconButton({super.key, required this.id, this.mediaType = 'movie'});

  final int id;
  final String mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(watchlistNotifierProvider).value?[id]?.accountStatus;
    final isWatched = status == 'watched';
    final isWatchlisted = status == 'watchlist';

    final icon = isWatched
        ? Icons.visibility
        : (isWatchlisted ? Icons.bookmark : Icons.bookmark_border);

    return IconButton(
      icon: Icon(icon, color: (isWatched || isWatchlisted) ? Colors.amber : null),
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
    final notifier = ref.read(watchlistNotifierProvider.notifier);
    try {
      switch (action) {
        case _WatchlistAction.watchlist:
          await notifier.addToWatchlist(id, mediaType: mediaType);
        case _WatchlistAction.watched:
          await notifier.markAsWatched(id, mediaType: mediaType);
        case _WatchlistAction.remove:
          await notifier.removeFromWatchlist(id);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update watchlist: $e')));
    }
  }
}
