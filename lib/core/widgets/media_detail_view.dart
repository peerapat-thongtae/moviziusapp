import 'package:flutter/material.dart';

import 'overlay_icon_button.dart';
import 'poster_banner.dart';
import 'trailer_player_dialog.dart';

/// One tab of a [MediaDetailView]: a [label] for the pinned `TabBar` and the
/// [slivers] rendered inside that tab's scroll view.
class MediaDetailTab {
  const MediaDetailTab({required this.label, required this.slivers});

  final String label;
  final List<Widget> slivers;
}

/// Shared tabbed shell for the movie and series detail pages, keeping the two
/// in visual sync (per the project's movie/series parity rule). A backdrop
/// banner (with an optional trailer play button) and a [header] block scroll
/// away Netflix-style while the [tabs]' `TabBar` pins to the top.
///
/// Rendered inside each page's own `Scaffold`/`Stack`, so it is intentionally
/// not a `Scaffold` itself — that lets the floating back button and entry fade
/// continue to live at the page level.
class MediaDetailView extends StatelessWidget {
  const MediaDetailView({
    super.key,
    required this.backdropPath,
    this.trailerKey,
    required this.header,
    required this.tabs,
    this.onRefresh,
  });

  final String backdropPath;
  final String? trailerKey;
  final Widget header;
  final List<MediaDetailTab> tabs;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final trailerKey = this.trailerKey;
    final onRefresh = this.onRefresh;

    final content = DefaultTabController(
      length: tabs.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PosterBanner(
                  imagePath: backdropPath,
                  isBackdrop: true,
                  height: 260,
                ),
                if (trailerKey != null)
                  OverlayIconButton(
                    icon: Icons.play_arrow,
                    iconSize: 40,
                    onPressed: () => showTrailerPlayer(context, trailerKey),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: header),
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  tabs: [for (final tab in tabs) Tab(text: tab.label)],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            for (final tab in tabs)
              Builder(
                builder: (context) => CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    ...tab.slivers,
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        notificationPredicate: (n) => n.depth == 0 || n.depth == 2,
        child: content,
      );
    }
    return content;
  }
}

/// Pins the [TabBar] with an opaque background so scrolled content doesn't show
/// through it.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}
