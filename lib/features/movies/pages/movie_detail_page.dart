import 'package:flutter/material.dart';

/// Placeholder detail screen reachable from a reel's title on Explore.
/// Static/mock content only — wiring this up to real movie data (overview,
/// cast, runtime, trailer) is a later task.
class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({super.key, required this.movieId, this.title});

  final int movieId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Movie Details')),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title ?? 'Untitled', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Movie ID: $movieId', style: textTheme.bodySmall),
              const SizedBox(height: 16),
              Text('Overview', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'This is placeholder overview text. Real movie details '
                '(synopsis, cast, runtime, trailer) will be wired up once '
                'the movie detail API is integrated.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
