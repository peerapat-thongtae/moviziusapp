import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/media_poster_card.dart';
import '../../search/providers/search_providers.dart';
import '../../search/widgets/search_results_grid.dart';
import '../../series/models/tv_discover_response.dart';
import '../providers/library_provider.dart';

const _statuses = ['watchlist', 'watching', 'waiting_next_ep', 'watched'];
const _statusLabels = ['Watchlist', 'Watching', 'Waiting', 'Watched'];

class TvLibraryPage extends ConsumerStatefulWidget {
  const TvLibraryPage({super.key});

  @override
  ConsumerState<TvLibraryPage> createState() => _TvLibraryPageState();
}

class _TvLibraryPageState extends ConsumerState<TvLibraryPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: _statuses.length, vsync: this)
    ..addListener(_onTabChanged);

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref
        .read(tvLibraryProvider.notifier)
        .setStatus(_statuses[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(tvLibraryProvider.notifier);
    final status = ref.watch(
      tvLibraryProvider.select((s) => s.value?.status ?? 'watchlist'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Series'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: SearchResultsGrid<TvShow>(
          key: ValueKey(status),
          state: ref.watch(tvLibraryProvider).whenData(
            (s) => SearchState(items: s.items, isLoadingMore: s.isLoadingMore),
          ),
          onRefresh: () async => notifier.setStatus(status),
          onLoadMore: notifier.loadMore,
          card: (context, show) => MediaPosterCard(
            posterPath: show.posterPath,
            title: show.name,
            onTap: () => context.push(
              RoutePaths.seriesDetailPath(show.id),
              extra: show,
            ),
          ),
        ),
      ),
    );
  }
}
