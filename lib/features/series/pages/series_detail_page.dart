import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_timezone.dart';
import '../../../core/constants/tmdb_image.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/episode_type_label.dart';
import '../../../core/widgets/imdb_badge.dart';
import '../../../core/widgets/media_detail_skeleton.dart';
import '../../../core/widgets/media_detail_view.dart';
import '../../../core/widgets/overlay_icon_button.dart';
import '../../../core/widgets/origin_country_row.dart';
import '../../../core/widgets/tag.dart';
import '../../../core/widgets/watch_providers_row.dart';
import '../../watchlist/models/tv_watchlist_item.dart';
import '../../watchlist/providers/tv_watchlist_provider.dart';
import '../../watchlist/widgets/watchlist_icon_button.dart';
import '../models/tv_discover_response.dart';
import '../tv_watch_progress.dart';
import '../providers/season_episodes_provider.dart';
import '../providers/series_detail_provider.dart';
import '../providers/continue_watching_provider.dart';

/// Picks the best YouTube trailer key out of [show]'s videos: an official
/// trailer if there is one, else any YouTube video, else none. Unlike
/// [Movie]'s videos, [TvShow]'s `site`/`type` are plain strings rather than
/// enums, so these are compared against TMDB's raw values directly.
/// TH-region streaming availability for [show], preferring subscription
/// (`flatrate`) providers and falling back to free/ad-supported ones, sorted
/// by TMDB's `display_priority`.
List<WatchProviderLogo> _watchProviderLogos(TvShow show) {
  final country = show.watchProviders;
  final providers = country?.flatrate;
  if (providers == null || providers.isEmpty) return const [];
  final sorted = [...providers]
    ..sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
  return [
    for (final p in sorted)
      WatchProviderLogo(
        providerId: p.providerId,
        providerName: p.providerName,
        logoPath: p.logoPath,
      ),
  ];
}

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

/// Reachable from the home hero slider or any show card, which already has a
/// [TvShow] fetched from a list/discover response (passed via the route's
/// `extra`) — that's rendered immediately as a placeholder for the first
/// paint. That list-shaped data is missing detail-only fields like
/// `created_by`, so this always also fetches the true `GET /tv/:id` via
/// [seriesDetailProvider] and swaps in the resolved show once it lands
/// (deep links, search, library, etc. have no placeholder and just show the
/// skeleton until then). Both share the same shell as [MovieDetailPage]: no
/// app bar background, just a back button floating over the content, with
/// the watchlist toggle living in the detail section next to the title
/// instead.
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
    final showAsync = ref.watch(seriesDetailProvider(seriesId));
    final resolvedShow = showAsync.value ?? show;

    final Widget body = resolvedShow != null
        ? _SeriesBody(show: resolvedShow, seriesId: seriesId)
        : showAsync.hasError
        ? _DetailError(
            onRetry: () => ref.invalidate(seriesDetailProvider(seriesId)),
          )
        : const MediaDetailSkeleton();

    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: body,
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

/// Shared error state for the detail page when the detail fetch fails.
class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load details.'),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
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
        widget.show.seasons.where((season) => season.seasonNumber != 0).toList()
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
    final creator = show.creator ?? 'Unknown';
    // Prefer the real `created_by` credits for the Crew section; only fall
    // back to a crew-derived Executive Producer credit when that's empty
    // (see [TvShow.creator]).
    final creatorCrew = show.createdBy.isNotEmpty
        ? [
            for (final c in show.createdBy)
              (id: c.id, name: c.name, profilePath: c.profilePath),
          ]
        : [
            for (final c in show.credits?.crew ?? const [])
              if (c.job == 'Executive Producer')
                (id: c.id, name: c.name, profilePath: c.profilePath),
          ].take(1).toList();
    final selectedSeasonNumber = _selectedSeasonNumber;
    final watchProviderLogos = _watchProviderLogos(show);

    final item = ref.watch(tvWatchlistNotifierProvider).value?[widget.seriesId];
    final watchedEpisodeIdsBySeason = <int, Set<int>>{};
    for (final e in item?.episodeWatched ?? const []) {
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
              Expanded(child: Text(show.name, style: textTheme.headlineSmall)),
              WatchlistIconButton(id: widget.seriesId, mediaType: 'tv'),
            ],
          ),
          if (show.genres.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final genre in show.genres) Tag(label: genre.name),
              ],
            ),
          ],
          const SizedBox(height: 12),
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
              if (show.originCountry.isNotEmpty) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 14,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(width: 10),
                OriginCountryRow(countries: show.originCountry),
              ],
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
          const SizedBox(height: 12),
          _WatchSummaryCard(item: item, show: show),
          if (watchProviderLogos.isNotEmpty) ...[
            const SizedBox(height: 12),
            WatchProvidersRow(providers: watchProviderLogos),
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
                    if (show.credits?.cast.isNotEmpty == true) ...[
                      const Divider(height: 32),
                      Text('Cast', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CastRow(
                        items: [
                          for (final c in show.credits!.cast)
                            _CastItem(
                              id: c.id,
                              name: c.name,
                              character: c.character,
                              profilePath: c.profilePath,
                            ),
                        ],
                      ),
                    ],
                    if (creatorCrew.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text('Crew', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CastRow(
                        items: [
                          for (final c in creatorCrew)
                            _CastItem(
                              id: c.id,
                              name: c.name,
                              character: 'Creator',
                              profilePath: c.profilePath,
                            ),
                        ],
                      ),
                    ],
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

/// Compact watch-progress summary in the series header, driven by the show's
/// watchlist [item] status: where the user is (last watched season/episode),
/// how much is left, or — once caught up — when the next episode airs.
class _WatchSummaryCard extends StatelessWidget {
  const _WatchSummaryCard({required this.item, required this.show});

  final TvWatchlistItem? item;
  final TvShow show;

  /// Formats [dt] as `YYYY-MM-DD HH:mm` in Asia/Bangkok (UTC+7, no DST).
  String _formatAirDateTime(DateTime dt) {
    final local = dt.toUtc().add(kAppTimezoneOffset);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = tvWatchProgress(item, show);
    final status = item?.accountStatus ?? '';
    final remaining = (progress.total - progress.watched).clamp(
      0,
      progress.total,
    );

    // Highest watched position, ignoring season 0 specials.
    EpisodeWatched? lastWatched;
    for (final e in item?.episodeWatched ?? const <EpisodeWatched>[]) {
      if (e.seasonNumber == 0) continue;
      if (lastWatched == null ||
          e.seasonNumber > lastWatched.seasonNumber ||
          (e.seasonNumber == lastWatched.seasonNumber &&
              e.episodeNumber > lastWatched.episodeNumber)) {
        lastWatched = e;
      }
    }

    // Next episode to air: prefer the detail's Episode (richer — has a name),
    // falling back to the watchlist item's TvAiredEpisode.
    final nextEp = show.nextEpisodeToAir;
    final nextEpItem = item?.nextEpisodeToAir;
    final hasNext = nextEp != null || nextEpItem != null;

    final notStarted =
        progress.watched == 0 &&
        status != 'watched' &&
        status != 'waiting_next_ep';
    if (notStarted) {
      return _SummaryContainer(
        icon: Icons.play_circle_outline,
        title: 'Not started',
        subtitle: progress.total > 0 ? '${progress.total} episodes' : null,
      );
    }

    final waitingNext =
        status == 'waiting_next_ep' ||
        (progress.watched > 0 && remaining <= 0 && hasNext);
    if (waitingNext && hasNext) {
      final season = nextEp?.seasonNumber ?? nextEpItem!.seasonNumber;
      final number = nextEp?.episodeNumber ?? nextEpItem!.episodeNumber;
      final name = nextEp?.name ?? '';
      final nextAirDate = (nextEp != null && nextEp.airDate.isNotEmpty)
          ? DateTime.tryParse(nextEp.airDate)
          : nextEpItem?.airDate;
      final airDate = nextAirDate != null
          ? _formatAirDateTime(nextAirDate)
          : '';
      final label = [
        'S${season}E$number',
        if (name.isNotEmpty) name,
      ].join(' · ');
      final badgeLabel = episodeTypeLabel(
        nextEp?.episodeType ?? nextEpItem?.episodeType ?? '',
        number,
      );
      return _SummaryContainer(
        icon: Icons.schedule,
        title: 'Next episode',
        highlight: label,
        subtitle: airDate.isNotEmpty ? 'Airs $airDate' : null,
        badgeLabel: badgeLabel,
      );
    }

    // Fully caught up on an ended show, nothing upcoming.
    if (remaining <= 0 && progress.watched > 0) {
      return _SummaryContainer(
        icon: Icons.check_circle_outline,
        title: 'All caught up',
        subtitle: progress.total > 0
            ? 'Watched ${progress.total} episodes'
            : null,
      );
    }

    // Watching: partway through.
    return _SummaryContainer(
      icon: Icons.play_arrow_rounded,
      title: 'Watching',
      highlight: lastWatched != null
          ? 'Season ${lastWatched.seasonNumber} • Episode ${lastWatched.episodeNumber}'
          : null,
      subtitle:
          '$remaining ${remaining == 1 ? 'episode' : 'episodes'} remaining',
      progress: progress.fraction,
    );
  }
}

/// Presentational shell for [_WatchSummaryCard]'s four states: an icon + title,
/// an optional emphasised [highlight] line and [subtitle], and — for the
/// watching state — an animated progress bar.
class _SummaryContainer extends StatelessWidget {
  const _SummaryContainer({
    required this.icon,
    required this.title,
    this.highlight,
    this.subtitle,
    this.progress,
    this.badgeLabel,
  });

  final IconData icon;
  final String title;
  final String? highlight;
  final String? subtitle;
  final double? progress;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final highlight = this.highlight;
    final subtitle = this.subtitle;
    final progress = this.progress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    if (highlight != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              highlight,
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (badgeLabel != null) ...[
                            const SizedBox(width: 6),
                            Tag(label: badgeLabel!),
                          ],
                        ],
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal, lazily-built (not `shrinkWrap`) row of season pills built from
/// the show's already-fetched [Season] metadata — no extra fetch needed just
/// to populate the selector itself.
class _CastItem {
  const _CastItem({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
}

class _CastRow extends StatelessWidget {
  const _CastRow({required this.items});

  final List<_CastItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final profilePath = item.profilePath;

          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 12),
            child: GestureDetector(
              onTap: () => context.push(
                RoutePaths.personDetailPath(item.id),
                extra: item.name,
              ),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage:
                          profilePath != null && profilePath.isNotEmpty
                          ? NetworkImage(TmdbImage.profile(profilePath))
                          : null,
                      child: profilePath == null || profilePath.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      style: textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (item.character != null && item.character!.isNotEmpty)
                      Text(
                        item.character!,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
      for (final e
          in ref
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (episode.airDate.isNotEmpty) episode.airDate,
                            if (episode.runtime != null) '${episode.runtime}m',
                          ].join(' • '),
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
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
