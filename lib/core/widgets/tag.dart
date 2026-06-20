import 'package:flutter/material.dart';

/// Small pill-shaped label for things like genres or categories. Defaults to
/// the current [ColorScheme]'s secondary container, but accepts overrides for
/// contexts that render over media (e.g. a translucent overlay on video).
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.backgroundColor, this.foregroundColor});

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor ?? colorScheme.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
