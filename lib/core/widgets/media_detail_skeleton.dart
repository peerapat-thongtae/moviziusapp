import 'package:flutter/material.dart';

import 'skeleton_loader.dart';

/// Loading placeholder for the movie/series detail pages while `GET /movie/:id`
/// or `GET /tv/:id` is in flight. Mirrors [MediaDetailView]'s layout — backdrop
/// banner, title/meta header, then a block of overview lines — so the reveal
/// into real content doesn't shift. Shared so the two detail pages stay in sync.
class MediaDetailSkeleton extends StatelessWidget {
  const MediaDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        Skeleton(height: 260, borderRadius: 0),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 220, height: 26),
              SizedBox(height: 12),
              Skeleton(width: 120, height: 16),
              SizedBox(height: 12),
              Skeleton(width: 180, height: 14),
              SizedBox(height: 8),
              Skeleton(width: 140, height: 14),
              SizedBox(height: 16),
              Row(
                children: [
                  Skeleton(width: 64, height: 28, borderRadius: 999),
                  SizedBox(width: 8),
                  Skeleton(width: 72, height: 28, borderRadius: 999),
                  SizedBox(width: 8),
                  Skeleton(width: 56, height: 28, borderRadius: 999),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: double.infinity, height: 14),
              SizedBox(height: 8),
              Skeleton(width: double.infinity, height: 14),
              SizedBox(height: 8),
              Skeleton(width: 240, height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
