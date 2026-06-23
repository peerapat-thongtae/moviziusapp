import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/imdb_badge.dart';
import '../../../core/widgets/overlay_icon_button.dart';
import '../../../core/widgets/poster_banner.dart';
import '../../../core/widgets/tag.dart';
import '../../../core/widgets/trailer_player_dialog.dart';
import '../../watchlist/widgets/watchlist_icon_button.dart';
import '../models/tv_discover_response.dart';

/// Picks the best YouTube trailer key out of [show]'s videos: an official
/// trailer if there is one, else any YouTube video, else none. Unlike
/// [Movie]'s videos, [TvShow]'s `site`/`type` are plain strings rather than
/// enums, so these are compared against TMDB's raw values directly.
String? _trailerKey(TvShow show) {
  final videos = show.videos?.results ?? const [];
  for (final video in videos) {
    if (video.site == 'YouTube' && video.type == 'Trailer' && video.official) {
      return video.key;
    }
  }
  for (final video in videos) {
    if (video.site == 'YouTube') return video.key;
  }
  return null;
}

/// Reachable from the home hero slider, which already has the full
/// [TvShow] fetched (passed via the route's `extra`) — that's rendered in
/// full below. Other entry points fall back to a minimal display. Both
/// share the same shell as [MovieDetailPage]: no app bar background, just a
/// back button floating over the content, with the watchlist toggle living
/// in the detail section next to the title instead.
class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({
    super.key,
    required this.seriesId,
    this.title,
    this.show,
  });

  final int seriesId;
  final String? title;
  final TvShow? show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = this.show;

    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: show == null
                ? _FallbackBody(seriesId: seriesId, title: title)
                : _SeriesBody(show: show, seriesId: seriesId),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: OverlayIconButton(
                icon: Icons.arrow_back,
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBody extends StatelessWidget {
  const _FallbackBody({required this.seriesId, this.title});

  final int seriesId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title ?? 'Untitled',
                    style: textTheme.headlineSmall,
                  ),
                ),
                WatchlistIconButton(id: seriesId, mediaType: 'tv'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Series ID: $seriesId', style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('Overview', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'This is placeholder overview text. Real series details '
              '(synopsis, seasons, cast, networks) will be wired up once '
              'the series detail API is integrated.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesBody extends StatelessWidget {
  const _SeriesBody({required this.show, required this.seriesId});

  final TvShow show;
  final int seriesId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final creator = show.createdBy.isNotEmpty
        ? show.createdBy.first.name
        : 'Unknown';
    final trailerKey = _trailerKey(show);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              PosterBanner(
                imagePath: show.backdropPath,
                isBackdrop: true,
                height: 260,
              ),
              if (trailerKey != null)
                OverlayIconButton(
                  icon: Icons.play_arrow,
                  iconSize: 40,
                  onPressed: () => showTrailerPlayer(context, trailerKey),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(show.name, style: textTheme.headlineSmall),
                    ),
                    WatchlistIconButton(id: seriesId, mediaType: 'tv'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ImdbBadge(),
                    const SizedBox(width: 6),
                    Text(
                      show.voteAverage.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Text('(${show.voteCount})', style: textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${show.firstAirDate} • ${show.status}'),
                const SizedBox(height: 4),
                Text(
                  '${show.numberOfSeasons} Seasons • ${show.numberOfEpisodes} Episodes',
                ),
                const SizedBox(height: 4),
                Text('Creator: $creator'),
                if (show.genres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final genre in show.genres) Tag(label: genre.name),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text('Overview', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  show.overview.isEmpty
                      ? 'No overview available.'
                      : show.overview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
