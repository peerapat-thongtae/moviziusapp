import 'package:flutter/material.dart';

import '../constants/tmdb_image.dart';

/// Minimal shape both `Movie`'s and `TvShow`'s per-country `Flatrate` model
/// get mapped into, so this widget doesn't need to depend on either feature's
/// generated model classes.
class WatchProviderLogo {
  const WatchProviderLogo({
    required this.providerId,
    required this.providerName,
    this.logoPath,
  });

  final int providerId;
  final String providerName;
  final String? logoPath;
}

/// Row of streaming-provider logos (Netflix, Disney+, etc.) for a title's
/// regional availability, sourced from the TMDB per-title `watch/providers`
/// data already embedded in the detail response. Renders nothing when
/// [providers] is empty — most titles simply have no confirmed availability.
class WatchProvidersRow extends StatelessWidget {
  const WatchProvidersRow({super.key, required this.providers});

  final List<WatchProviderLogo> providers;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Watch on',
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final provider in providers)
              Tooltip(
                message: provider.providerName,
                child: _ProviderLogo(provider: provider),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.provider});

  final WatchProviderLogo provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logoPath = provider.logoPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: 36,
        child: logoPath == null || logoPath.isEmpty
            ? ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.live_tv,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Image.network(
                TmdbImage.logo(logoPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    ColoredBox(color: colorScheme.surfaceContainerHighest),
              ),
      ),
    );
  }
}
