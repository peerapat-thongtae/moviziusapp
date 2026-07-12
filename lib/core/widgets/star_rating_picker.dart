import 'package:flutter/material.dart';

/// Interactive 10-star picker with half-star granularity, reporting values
/// on a 1-10 scale in 0.5 steps since that's the scale the watchlist rating
/// API uses (each star is worth 1 point). Tap or drag horizontally across
/// the stars to pick a value.
class StarRatingPicker extends StatelessWidget {
  const StarRatingPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    this.starCount = 10,
    this.size = 28,
  });

  /// Value on a 1.0-10.0 scale, in 0.5 steps.
  final double rating;
  final ValueChanged<double> onChanged;
  final int starCount;
  final double size;

  void _updateFromLocalPosition(Offset localPosition, double width) {
    final starWidth = width / starCount;
    final rawStars = (localPosition.dx / starWidth).clamp(
      0.0,
      starCount.toDouble(),
    );
    final halfSteps = (rawStars * 2).round();
    final stars = (halfSteps / 2).clamp(0.5, starCount.toDouble());
    onChanged(stars);
  }

  @override
  Widget build(BuildContext context) {
    final starsValue = rating.clamp(0.0, starCount.toDouble());
    final width = size * starCount;

    return GestureDetector(
      onTapDown: (details) =>
          _updateFromLocalPosition(details.localPosition, width),
      onHorizontalDragUpdate: (details) =>
          _updateFromLocalPosition(details.localPosition, width),
      child: SizedBox(
        width: width,
        height: size,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < starCount; i++)
              _Star(fill: (starsValue - i).clamp(0.0, 1.0), size: size),
          ],
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.fill, required this.size});

  /// 0.0 (empty), 0.5 (half), or 1.0 (full).
  final double fill;
  final double size;

  IconData get _icon {
    if (fill >= 1.0) return Icons.star;
    if (fill >= 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_icon),
      tween: Tween(begin: 1.15, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(_icon, size: size, color: Colors.amber),
    );
  }
}
