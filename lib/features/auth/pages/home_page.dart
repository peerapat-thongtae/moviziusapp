import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/hero_provider.dart';
import '../../home/widgets/continue_watching_section.dart';
import '../../home/widgets/hero_slider.dart';
import '../../series/providers/continue_watching_provider.dart';
import '../../watchlist/providers/tv_watchlist_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(heroSliderProvider);
          ref.invalidate(continueWatchingProvider);
          ref.invalidate(tvWatchlistNotifierProvider);
          await Future.wait([
            ref.read(heroSliderProvider.future),
            ref.read(continueWatchingProvider.future),
            ref.read(tvWatchlistNotifierProvider.future),
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
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
