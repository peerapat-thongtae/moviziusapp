import 'dart:math' as math;

import '../watchlist/models/tv_watchlist_item.dart';
import 'models/tv_discover_response.dart';

/// Watched-episode progress for an in-progress series, combining the watchlist
/// notifier entry ([item], the source of the watched count) with the paginate
/// feed's [show] (the source of the total). Shared by the home rail card and
/// the Continue Watching grid so they compute progress identically.
({int watched, int total, double fraction}) tvWatchProgress(
  TvWatchlistItem? item,
  TvShow show,
) {
  // `max` keeps the bar live after an optimistic markEpisodeWatched (which
  // appends to episodeWatched without bumping countWatched).
  final watched = item == null
      ? 0
      : math.max(item.countWatched, item.episodeWatched.length);
  final total = show.numberOfEpisodes != 0
      ? show.numberOfEpisodes
      : (item?.numberOfEpisodes ?? 0);
  final fraction = total == 0 ? 0.0 : (watched / total).clamp(0.0, 1.0);
  return (watched: watched, total: total, fraction: fraction);
}
