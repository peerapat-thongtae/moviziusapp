import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/tmdb_image.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/tag.dart';
import '../models/hero_item.dart';
import '../providers/hero_provider.dart';

const _autoSlideInterval = Duration(seconds: 5);
const _pageAnimationDuration = Duration(milliseconds: 400);

/// Full-width, near-full-height hero slider at the top of the home page.
/// Merges movies and TV series (via [heroSliderProvider]) and auto-advances
/// through them, while still supporting manual swipe.
class HeroSlider extends ConsumerStatefulWidget {
  const HeroSlider({super.key});

  @override
  ConsumerState<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends ConsumerState<HeroSlider> {
  final _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  int _itemCount = 0;

  void _restartAutoSlide(int itemCount) {
    _itemCount = itemCount;
    _autoSlideTimer?.cancel();
    if (itemCount <= 1) return;
    _autoSlideTimer = Timer.periodic(_autoSlideInterval, (_) {
      final next = (_currentPage + 1) % _itemCount;
      _pageController.animateToPage(
        next,
        duration: _pageAnimationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // A manual swipe lands here too, so this simply resets the auto-slide
    // clock instead of fighting the user's gesture.
    _restartAutoSlide(_itemCount);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroItems = ref.watch(heroSliderProvider);
    final height = MediaQuery.sizeOf(context).height * 0.70;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: heroItems.when(
        loading: () => const ColoredBox(
          color: Colors.black12,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => const ColoredBox(
          color: Colors.black12,
          child: Center(child: Text('Could not load featured titles')),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const ColoredBox(color: Colors.black12);
          }
          if (_itemCount != items.length) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _restartAutoSlide(items.length),
            );
          }
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _HeroSlide(item: items[index]),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _PageIndicator(
                  count: items.length,
                  currentIndex: _currentPage,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.item});

  final HeroItem item;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return InkWell(
      onTap: () {
        switch (item.mediaType) {
          case HeroMediaType.movie:
            context.push(
              RoutePaths.movieDetailPath(item.id),
              extra: item.media,
            );
          case HeroMediaType.tv:
            context.push(
              RoutePaths.seriesDetailPath(item.id),
              extra: item.media,
            );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            TmdbImage.poster(item.posterPath),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const ColoredBox(color: Colors.black26),
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: Colors.black26),
          ),
          // Fades all the way to the exact page background color (not a
          // flat scrim) so the slider's bottom edge blends into the rest
          // of the Scaffold instead of showing a hard seam.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, surface],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(item.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tag(
                        label: item.mediaType == HeroMediaType.movie
                            ? 'Movie'
                            : 'Series',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.overview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A discover feed can return dozens of items, so a one-dot-per-item row
/// (the usual carousel indicator) would overflow the screen width. A
/// compact "current / total" pill stays a fixed size regardless of count.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${currentIndex + 1} / $count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
