import 'package:flutter/material.dart';

const _shimmerDuration = Duration(milliseconds: 1200);

/// Reusable, dependency-free shimmer placeholder used by "loading" states.
/// Renders a rounded rectangle with a horizontal light sweep driven by a single
/// repeating [AnimationController]. Deliberately "dumb" (no Riverpod, no model
/// types) so any section — hero, rails, grids — can compose [Skeleton] boxes for
/// its own loading layout. Colors derive from the M3 [ColorScheme] so it adapts
/// to the active theme.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _shimmerDuration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      colorScheme.onSurface.withValues(alpha: 0.08),
      base,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Slide the highlight band from left to right across the box.
          final dx = (_controller.value * 2) - 1;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(dx - 1, 0),
                end: Alignment(dx + 1, 0),
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
            child: child,
          );
        },
        child: SizedBox(width: widget.width, height: widget.height),
      ),
    );
  }
}
