import 'package:flutter/material.dart';

import '../constants/tmdb_image.dart';

/// Reusable, media-agnostic poster card: a poster that fills the available
/// space, with a title and an optional watch-progress bar below. Deliberately
/// "dumb" (no Riverpod, no model types) so both movies and series — in
/// horizontal rails and in grids — can reuse it. The card sizes to its parent,
/// so the caller controls the footprint (a `SizedBox` width in a rail, or the
/// grid cell's `childAspectRatio`).
class MediaPosterCard extends StatelessWidget {
  const MediaPosterCard({
    super.key,
    required this.posterPath,
    required this.title,
    this.progress,
    this.trailingText,
    this.onTap,
  });

  final String posterPath;
  final String title;

  /// `null` hides the progress bar (e.g. movies); `0..1` shows it (e.g. the
  /// watched/total ratio for an in-progress series).
  final double? progress;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                child: posterPath.isEmpty
                    ? ColoredBox(color: colorScheme.surfaceContainerHighest)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Image.network(
                          TmdbImage.poster(posterPath, size: 'w342'),
                          key: ValueKey(posterPath),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, prog) => prog == null
                              ? child
                              : const ColoredBox(color: Colors.black26),
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(color: Colors.black26),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            if (trailingText != null && trailingText!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                trailingText!,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
