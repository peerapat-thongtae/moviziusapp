import 'package:flutter/material.dart';

import '../constants/tmdb_image.dart';

/// Full-width image that fades into the page background at the bottom, used
/// as the header on movie/series detail pages. Mirrors the same
/// fade-to-`colorScheme.surface` technique used by the home hero slider, so
/// both screens read as one consistent visual language. Pass [isBackdrop] to
/// render a TMDB backdrop (wide, landscape) instead of a poster (narrow,
/// portrait) image.
class PosterBanner extends StatelessWidget {
  const PosterBanner({
    super.key,
    required this.imagePath,
    this.height = 320,
    this.isBackdrop = false,
  });

  final String imagePath;
  final double height;
  final bool isBackdrop;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    }

    final surface = Theme.of(context).colorScheme.surface;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            isBackdrop ? TmdbImage.backdrop(imagePath) : TmdbImage.poster(imagePath),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const ColoredBox(color: Colors.black26),
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: Colors.black26),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, surface],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
