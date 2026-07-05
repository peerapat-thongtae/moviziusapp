import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';

import '../../../core/constants/tmdb_image.dart';
import '../../../core/widgets/imdb_badge.dart';
import '../../../core/widgets/media_detail_skeleton.dart';
import '../../../core/widgets/media_detail_view.dart';
import '../../../core/widgets/overlay_icon_button.dart';
import '../../../core/widgets/origin_country_row.dart';
import '../../../core/widgets/tag.dart';
import '../../../core/widgets/watch_providers_row.dart';
import '../../watchlist/providers/watchlist_provider.dart';
import '../../watchlist/widgets/watchlist_icon_button.dart';
import '../models/movie_discover_response.dart';
import '../providers/movie_detail_provider.dart';

/// Picks the best YouTube trailer key out of [movie]'s videos: an official
/// trailer if there is one, else any YouTube video, else none.
/// TH-region streaming availability for [movie], preferring subscription
/// (`flatrate`) providers and falling back to free/ad-supported ones, sorted
/// by TMDB's `display_priority`.
List<WatchProviderLogo> _watchProviderLogos(Movie movie) {
  final country = movie.watchProviders;
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

String? _trailerKey(Movie movie) {
  final videos = movie.videos?.results ?? const [];
  for (final video in videos) {
    if (video.site == Site.YOU_TUBE &&
        video.type == VideoType.TRAILER &&
        video.official) {
      return video.key;
    }
  }
  for (final video in videos) {
    if (video.site == Site.YOU_TUBE) return video.key;
  }
  return null;
}

/// Reachable from the home hero slider, which already has the full
/// [Movie] fetched (passed via the route's `extra`) — that's rendered in
/// full below. Other entry points (e.g. the Explore tab's reel title, which
/// only passes a title string today) fall back to a minimal display. Both
/// share the same shell: no app bar background, just a back button floating
/// over the content, with the watchlist toggle living in the detail section
/// next to the title instead.
class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({
    super.key,
    required this.movieId,
    this.title,
    this.movie,
  });

  final int movieId;
  final String? title;
  final Movie? movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = this.movie;

    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: movie == null
                ? _MovieLoader(movieId: movieId)
                : _MovieBody(
                    movie: movie,
                    movieId: movieId,
                    onRefresh: () async {
                      ref.invalidate(watchlistNotifierProvider);
                      await ref.read(watchlistNotifierProvider.future);
                    },
                  ),
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

/// Fetches the full [Movie] from `GET /movie/:id` for entry points that only
/// pass an id (deep links, the Explore reel title, etc.), showing skeleton
/// loading while it resolves and an error state with retry on failure.
class _MovieLoader extends ConsumerWidget {
  const _MovieLoader({required this.movieId});

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieAsync = ref.watch(movieDetailProvider(movieId));

    return movieAsync.when(
      loading: () => const MediaDetailSkeleton(),
      error: (error, stackTrace) => _DetailError(
        onRetry: () => ref.invalidate(movieDetailProvider(movieId)),
      ),
      data: (movie) => _MovieBody(
        movie: movie,
        movieId: movieId,
        onRefresh: () async {
          ref.invalidate(movieDetailProvider(movieId));
          ref.invalidate(watchlistNotifierProvider);
          await ref.read(watchlistNotifierProvider.future);
          await ref.read(movieDetailProvider(movieId).future);
        },
      ),
    );
  }
}

/// Shared error state for the detail pages when the detail fetch fails.
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

class _MovieBody extends StatelessWidget {
  const _MovieBody({
    required this.movie,
    required this.movieId,
    this.onRefresh,
  });

  final Movie movie;
  final int movieId;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final releaseDate =
        movie.effectiveReleaseDate?.toIso8601String().split('T').first ??
        'Unknown';
    final watchProviderLogos = _watchProviderLogos(movie);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(movie.title, style: textTheme.headlineSmall),
              ),
              WatchlistIconButton(id: movieId),
            ],
          ),
          if (movie.genres.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final genre in movie.genres) Tag(label: genre.name),
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
                movie.voteAverage.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Text('(${movie.voteCount})', style: textTheme.bodySmall),
              if (movie.originCountry.isNotEmpty) ...[
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
                OriginCountryRow(countries: movie.originCountry),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text('$releaseDate • ${movie.status}'),
          const SizedBox(height: 4),
          Text('Director: ${movie.director ?? 'Unknown'}'),
          if (movie.runtime > 0) ...[
            const SizedBox(height: 4),
            Text('${movie.runtime} min'),
          ],
          if (watchProviderLogos.isNotEmpty) ...[
            const SizedBox(height: 12),
            WatchProvidersRow(providers: watchProviderLogos),
          ],
        ],
      ),
    );

    return MediaDetailView(
      backdropPath: movie.backdropPath,
      trailerKey: _trailerKey(movie),
      onRefresh: onRefresh,
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
                      movie.overview.isEmpty
                          ? 'No overview available.'
                          : movie.overview,
                    ),
                    if (movie.casts?.cast.isNotEmpty == true) ...[
                      const Divider(height: 32),
                      Text('Cast', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CastRow(
                        items: [
                          for (final c in movie.casts!.cast)
                            _CastItem(
                              id: c.id,
                              name: c.name,
                              character: c.character,
                              profilePath: c.profilePath,
                            ),
                        ],
                      ),
                    ],
                    if (movie.casts?.crew
                            .where(
                              (c) => c.job == 'Director' || c.job == 'Writer',
                            )
                            .isNotEmpty ==
                        true) ...[
                      const Divider(height: 32),
                      Text('Crew', style: textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CastRow(
                        items: [
                          for (final c in movie.casts!.crew.where(
                            (c) => c.job == 'Director' || c.job == 'Writer',
                          ))
                            _CastItem(
                              id: c.id,
                              name: c.name,
                              character: c.job,
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
      ],
    );
  }
}
