import 'package:flutter/material.dart';

/// Circular semi-transparent icon button meant to sit on top of media
/// (a video, a backdrop image) where a plain [IconButton] wouldn't have
/// enough contrast against an unpredictable background.
class OverlayIconButton extends StatelessWidget {
  const OverlayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }
}
