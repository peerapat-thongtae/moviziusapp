import 'package:flutter/material.dart';

import '../utils/country_flag.dart';

/// Plain-text row of flag + ISO code (e.g. 🇹🇭 TH · 🇰🇷 KR · 🇺🇸 US) for a
/// title's origin countries. Renders nothing when [countries] is empty.
class OriginCountryRow extends StatelessWidget {
  const OriginCountryRow({super.key, required this.countries});

  final List<String> countries;

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Text(
      countries.map((c) => '${countryFlagEmoji(c)} $c').join(' · '),
      style: textTheme.bodyMedium,
    );
  }
}
