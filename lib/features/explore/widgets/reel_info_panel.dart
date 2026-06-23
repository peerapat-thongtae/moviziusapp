import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/imdb_badge.dart';
import '../../../core/widgets/tag.dart';
import '../models/explore_media_type.dart';
import '../models/explore_video.dart';

/// Bottom-left overlay showing a reel's metadata: title, rating, and the
/// fields relevant to its [ExploreMediaType] (release info vs. season info).
class ReelInfoPanel extends StatelessWidget {
  const ReelInfoPanel({
    super.key,
    required this.video,
    required this.mediaType,
  });

  final ExploreVideo video;
  final ExploreMediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final movieId = int.tryParse(video.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: movieId == null
              ? null
              : () => context.push(
                  RoutePaths.movieDetailPath(movieId),
                  extra: video.title,
                ),
          child: Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ImdbBadge(),
            const SizedBox(width: 6),
            Text(
              video.voteAverage.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${video.voteCount})',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._metaLines().map(
          (line) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
        if (video.genres.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final genre in video.genres)
                Tag(
                  label: genre,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<String> _metaLines() {
    return switch (mediaType) {
      ExploreMediaType.movies => [
        '${video.releaseDate} • ${video.status}',
        'Director: ${video.director}',
      ],
      ExploreMediaType.series => [
        '${video.firstAirDate} • ${video.status}',
        '${video.totalSeasons} Seasons • ${video.totalEpisodes} Episodes',
        'Creator: ${video.creator}',
      ],
    };
  }
}
