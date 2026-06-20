import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Explore tab is the thing actually on screen right now — i.e.
/// it's the active bottom-nav branch *and* nothing (like the movie detail
/// page) is pushed on top of it. Written by `MainShell`, read by
/// `ExplorePage` to pause/resume reel playback.
final exploreTabVisibleProvider =
    NotifierProvider<ExploreTabVisibleNotifier, bool>(
      ExploreTabVisibleNotifier.new,
    );

class ExploreTabVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
