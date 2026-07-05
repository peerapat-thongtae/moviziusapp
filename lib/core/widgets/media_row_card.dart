import 'package:flutter/material.dart';

import '../constants/tmdb_image.dart';
import 'skeleton_loader.dart';
import 'tag.dart';

/// Generic horizontal media card — poster on the left, detail column on the
/// right. Mirrors [MediaPosterCard] (vertical) but laid out as a Row.
/// Accepts raw display data so it stays media-agnostic (movies, TV series, etc.).
class MediaRowCard extends StatelessWidget {
  const MediaRowCard({
    super.key,
    required this.posterPath,
    required this.title,
    required this.voteAverage,
    this.subtitleLine1,
    this.subtitleLine2,
    this.badgeLabel,
    this.trailing,
    this.onTap,
  });

  final String? posterPath;
  final String title;
  final double voteAverage;

  /// First subtitle line, e.g. "S2 E5 · 21:00".
  final String? subtitleLine1;

  /// Second subtitle line, e.g. episode name.
  final String? subtitleLine2;

  /// Optional small pill shown under the title, e.g. "Season Finale".
  final String? badgeLabel;

  /// Optional widget aligned to the bottom-right of the detail column,
  /// e.g. a WatchlistIconButton.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poster(posterPath: posterPath),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: trailing != null ? 32 : 0,
                            ),
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (subtitleLine1 != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    subtitleLine1!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (badgeLabel != null) ...[
                                  const SizedBox(width: 6),
                                  Tag(label: badgeLabel!),
                                ],
                              ],
                            ),
                          ],
                          if (subtitleLine2 != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitleLine2!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      if (trailing != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              iconButtonTheme: IconButtonThemeData(
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            child: trailing!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.posterPath});

  final String? posterPath;

  @override
  Widget build(BuildContext context) {
    final path = posterPath;
    if (path == null || path.isEmpty) {
      return Container(
        width: 80,
        height: 120,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    return Image.network(
      TmdbImage.poster(path, size: 'w185'),
      width: 80,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 80,
        height: 120,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

/// Shimmer placeholder matching [MediaRowCard]'s layout.
class MediaRowCardSkeleton extends StatelessWidget {
  const MediaRowCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: 80, height: 120, borderRadius: 0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    const Skeleton(width: 80, height: 12),
                    const SizedBox(height: 6),
                    const Skeleton(width: 140, height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
