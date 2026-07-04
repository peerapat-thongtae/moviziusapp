import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/search_providers.dart';

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  childAspectRatio: 0.55,
  crossAxisSpacing: 12,
  mainAxisSpacing: 16,
);

/// Base grid padding. The bottom value is combined at build time with the
/// safe-area bottom inset ([_gridPaddingOf]) so content clears the Android
/// system navigation bar on pushed pages that have no bottom nav bar. Inside
/// the shell the Scaffold's bottomNavigationBar already consumes that inset,
/// so it reads 0 there and nothing is double-padded.
EdgeInsets _gridPaddingOf(BuildContext context) =>
    EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.paddingOf(context).bottom);

/// Extra bottom padding reserved while loading more so the trailing spinner
/// sits in a gap below the last row instead of overlapping the last cards.
const _loadMoreExtent = 56.0;

/// Generic results area for a search tab: renders the loading skeleton, empty /
/// error states, and the 2-column [card]-builder grid with pull-to-refresh and
/// infinite scroll. Reused symmetrically by the movie and tv tabs.
class SearchResultsGrid<T> extends StatefulWidget {
  const SearchResultsGrid({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.card,
  });

  final AsyncValue<SearchState<T>> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item) card;

  @override
  State<SearchResultsGrid<T>> createState() => _SearchResultsGridState<T>();
}

class _SearchResultsGridState<T> extends State<SearchResultsGrid<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.state.when(
      loading: () => const _SkeletonGrid(),
      error: (error, _) => _Message(
        icon: Icons.error_outline,
        text: 'Could not load results.',
        onRetry: widget.onRefresh,
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return const _Message(
            icon: Icons.search_off_rounded,
            text: 'No results. Try different filters.',
          );
        }
        final gridPadding = _gridPaddingOf(context);
        return AppRefreshIndicator(
          onRefresh: widget.onRefresh,
          child: Stack(
            children: [
              GridView.builder(
                controller: _scrollController,
                padding: state.isLoadingMore
                    ? gridPadding.add(
                        const EdgeInsets.only(bottom: _loadMoreExtent),
                      ) as EdgeInsets
                    : gridPadding,
                gridDelegate: _gridDelegate,
                itemCount: state.items.length,
                itemBuilder: (context, index) =>
                    widget.card(context, state.items[index]),
              ),
              if (state.isLoadingMore)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Loading placeholder that mirrors the card grid layout (poster box + title).
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: _gridPaddingOf(context),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _gridDelegate,
      itemCount: 6,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(child: Skeleton(width: double.infinity)),
          SizedBox(height: 8),
          Skeleton(width: 120, height: 14),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            text,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
