import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/tmdb_image.dart';
import '../../../core/widgets/imdb_badge.dart';
import '../../../core/widgets/media_detail_view.dart';
import '../../../core/widgets/overlay_icon_button.dart';
import '../../../core/widgets/tag.dart';
import '../../watchlist/providers/tv_watchlist_provider.dart';
import '../../watchlist/widgets/watchlist_icon_button.dart';
import '../models/tv_discover_response.dart';
import '../providers/season_episodes_provider.dart';
import '../providers/continue_watching_provider.dart';

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

class _SeriesBody extends ConsumerStatefulWidget {
  const _SeriesBody({required this.show, required this.seriesId});

  final TvShow show;
  final int seriesId;

  @override
  ConsumerState<_SeriesBody> createState() => _SeriesBodyState();
}

class _SeriesBodyState extends ConsumerState<_SeriesBody> {
  late final List<Season> _seasons;
  int? _selectedSeasonNumber;
  bool _showUnwatchedOnly = false;

  @override
  void initState() {
    super.initState();
    _seasons =
        widget.show.seasons
            .where((season) => season.seasonNumber != 0)
            .toList()
          ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    if (_seasons.isNotEmpty) {
      final defaultSeason = _seasons.firstWhere(
        (season) => season.seasonNumber == 1,
        orElse: () => _seasons.first,
      );
      _selectedSeasonNumber = defaultSeason.seasonNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final show = widget.show;
    final creator = show.createdBy.isNotEmpty
        ? show.createdBy.first.name
        : 'Unknown';
    final selectedSeasonNumber = _selectedSeasonNumber;

    final watchedEpisodeIdsBySeason = <int, Set<int>>{};
    for (final e
        in ref
                .watch(tvWatchlistNotifierProvider)
                .value?[widget.seriesId]
                ?.episodeWatched ??
            const []) {
      (watchedEpisodeIdsBySeason[e.seasonNumber] ??= {}).add(e.episodeId);
    }
    final visibleSeasons = _showUnwatchedOnly
        ? _seasons
              .where(
                (s) =>
                    (watchedEpisodeIdsBySeason[s.seasonNumber]?.length ?? 0) <
                    s.episodeCount,
              )
              .toList()
        : _seasons;
    final effectiveSelectedSeasonNumber =
        selectedSeasonNumber != null &&
            visibleSeasons.any((s) => s.seasonNumber == selectedSeasonNumber)
        ? selectedSeasonNumber
        : (visibleSeasons.isNotEmpty
              ? visibleSeasons.first.seasonNumber
              : null);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(show.name, style: textTheme.headlineSmall),
              ),
              WatchlistIconButton(id: widget.seriesId, mediaType: 'tv'),
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
        ],
      ),
    );

    return MediaDetailView(
      backdropPath: show.backdropPath,
      trailerKey: _trailerKey(show),
      onRefresh: () async {
        ref.invalidate(tvWatchlistNotifierProvider);
        ref.invalidate(continueWatchingProvider);
        ref.invalidate(seasonEpisodesProvider);
        await ref.read(tvWatchlistNotifierProvider.future);
      },
      header: header,
      tabs: [
        MediaDetailTab(
          label: 'Overview',
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ),
          ],
        ),
        if (_seasons.isNotEmpty)
          MediaDetailTab(
            label: 'Episodes',
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(
                          () => _showUnwatchedOnly = !_showUnwatchedOnly,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showUnwatchedOnly,
                              onChanged: (value) => setState(
                                () => _showUnwatchedOnly = value ?? false,
                              ),
                            ),
                            const Text('Unwatched only'),
                          ],
                        ),
                      ),
                      if (visibleSeasons.isNotEmpty &&
                          effectiveSelectedSeasonNumber != null) ...[
                        const SizedBox(height: 4),
                        _SeasonSelector(
                          seasons: visibleSeasons,
                          selectedSeasonNumber: effectiveSelectedSeasonNumber,
                          onSelected: (seasonNumber) => setState(
                            () => _selectedSeasonNumber = seasonNumber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (visibleSeasons.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('All caught up — no unwatched episodes.'),
                    ),
                  ),
                )
              else if (effectiveSelectedSeasonNumber != null)
                _EpisodeSliver(
                  seriesId: widget.seriesId,
                  seasonNumber: effectiveSelectedSeasonNumber,
                  showUnwatchedOnly: _showUnwatchedOnly,
                ),
            ],
          ),
      ],
    );
  }
}

/// Horizontal, lazily-built (not `shrinkWrap`) row of season pills built from
/// the show's already-fetched [Season] metadata — no extra fetch needed just
/// to populate the selector itself.
class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.seasons,
    required this.selectedSeasonNumber,
    required this.onSelected,
  });

  final List<Season> seasons;
  final int selectedSeasonNumber;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        itemBuilder: (context, index) {
          final season = seasons[index];
          final selected = season.seasonNumber == selectedSeasonNumber;
          final label = 'Season ${season.seasonNumber}';

          return Padding(
            padding: EdgeInsets.only(
              right: index == seasons.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onSelected(season.seasonNumber),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  child: Text(label),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fetches and renders the episode list for one season as a sliver, so it
/// stays lazily built inside the page's [CustomScrollView] even when a
/// season has many episodes.
class _EpisodeSliver extends ConsumerWidget {
  const _EpisodeSliver({
    required this.seriesId,
    required this.seasonNumber,
    required this.showUnwatchedOnly,
  });

  final int seriesId;
  final int seasonNumber;
  final bool showUnwatchedOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(
      seasonEpisodesProvider((seriesId: seriesId, seasonNumber: seasonNumber)),
    );
    final watchedIds = {
      for (final e in ref
              .watch(tvWatchlistNotifierProvider)
              .value?[seriesId]
              ?.episodeWatched ??
          const [])
        e.episodeId,
    };

    return episodesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Failed to load episodes.')),
        ),
      ),
      data: (episodes) {
        final visibleEpisodes = showUnwatchedOnly
            ? episodes.where((e) => !watchedIds.contains(e.id)).toList()
            : episodes;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _EpisodeRow(
                key: ValueKey('${seasonNumber}_${visibleEpisodes[index].id}'),
                seriesId: seriesId,
                episode: visibleEpisodes[index],
                isWatched: watchedIds.contains(visibleEpisodes[index].id),
              ),
              childCount: visibleEpisodes.length,
            ),
          ),
        );
      },
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
  const _EpisodeRow({
    super.key,
    required this.seriesId,
    required this.episode,
    required this.isWatched,
  });

  final int seriesId;
  final Episode episode;
  final bool isWatched;

  Future<void> _markWatched(BuildContext context, WidgetRef ref) async {
    if (isWatched) return;
    try {
      await ref
          .read(tvWatchlistNotifierProvider.notifier)
          .markEpisodeWatched(
            showId: seriesId,
            episodeId: episode.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark episode watched: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final stillPath = episode.stillPath;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 120,
                height: 68,
                child: stillPath == null || stillPath.isEmpty
                    ? ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      )
                    : Image.network(
                        TmdbImage.still(stillPath),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : const ColoredBox(color: Colors.black26),
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(color: Colors.black26),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${episode.episodeNumber}. ${episode.name}',
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (episode.airDate.isNotEmpty) episode.airDate,
                      if (episode.runtime != null) '${episode.runtime}m',
                    ].join(' • '),
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.overview.isEmpty
                        ? 'No overview available.'
                        : episode.overview,
                    style: textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isWatched ? 'Watched' : 'Mark as watched',
              onPressed: isWatched ? null : () => _markWatched(context, ref),
              disabledColor: Colors.amber,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.visibility,
                  key: ValueKey(isWatched),
                  color: isWatched ? Colors.amber : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
