import 'package:flutter/material.dart';

/// Small yellow "IMDb" pill shown next to a vote average/count, reused by
/// both the Explore reel overlay and the movie/series detail pages.
class ImdbBadge extends StatelessWidget {
  const ImdbBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'IMDb',
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
