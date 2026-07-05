import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_refresh_indicator.dart';
import '../../home/providers/hero_provider.dart';
import '../../home/providers/upcoming_movies_provider.dart';
import '../../home/providers/upcoming_series_provider.dart';
import '../../home/widgets/continue_watching_section.dart';
import '../../home/widgets/hero_slider.dart';
import '../../home/widgets/upcoming_movies_section.dart';
import '../../home/widgets/upcoming_series_section.dart';
import '../../series/providers/continue_watching_provider.dart';
import '../../watchlist/providers/tv_watchlist_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(heroSliderProvider);
          ref.invalidate(continueWatchingProvider);
          ref.invalidate(tvWatchlistNotifierProvider);
          ref.invalidate(upcomingMoviesProvider);
          ref.invalidate(upcomingSeriesProvider);
          await Future.wait([
            ref.read(heroSliderProvider.future),
            ref.read(continueWatchingProvider.future),
            ref.read(tvWatchlistNotifierProvider.future),
            ref.read(upcomingMoviesProvider.future),
            ref.read(upcomingSeriesProvider.future),
          ]);
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroSlider(),
              SizedBox(height: 8),
              ContinueWatchingSection(),
              SizedBox(height: 8),
              _SectionDivider(),
              SizedBox(height: 8),
              UpcomingMoviesSection(),
              SizedBox(height: 8),
              _SectionDivider(),
              SizedBox(height: 8),
              UpcomingSeriesSection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline separator between home page sections, inset to match each
/// section's header padding.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    );
  }
}
