import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/explore/providers/explore_visibility_provider.dart';
import 'route_observer.dart';
import 'widgets/animated_bottom_nav_bar.dart';

// Must match the branch order of the StatefulShellRoute in app_router.dart.
const _exploreBranchIndex = 2;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with RouteAware {
  bool _coveredByPushedRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _syncExploreVisibility();
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _syncExploreVisibility();
    }
  }

  // Fires when another route (e.g. the movie detail page) is pushed on top
  // of this shell.
  @override
  void didPushNext() {
    _coveredByPushedRoute = true;
    _syncExploreVisibility();
  }

  // Fires when that pushed route is popped back to this shell.
  @override
  void didPopNext() {
    _coveredByPushedRoute = false;
    _syncExploreVisibility();
  }

  // `didChangeDependencies`/`didUpdateWidget` run during the widget tree's
  // build phase, where Riverpod disallows modifying provider state. Defer to
  // a microtask so the write lands just after the current build completes.
  void _syncExploreVisibility() {
    final isVisible =
        widget.navigationShell.currentIndex == _exploreBranchIndex &&
        !_coveredByPushedRoute;
    Future(() {
      if (!mounted) return;
      ref.read(exploreTabVisibleProvider.notifier).set(isVisible);
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: widget.navigationShell.goBranch,
      ),
    );
  }
}
