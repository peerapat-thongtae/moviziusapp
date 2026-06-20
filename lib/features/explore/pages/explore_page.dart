import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../watchlist/providers/watchlist_provider.dart';
import '../models/explore_media_type.dart';
import '../models/explore_video.dart';
import '../providers/explore_videos_provider.dart';
import '../providers/explore_visibility_provider.dart';
import '../widgets/reel_info_panel.dart';
import '../widgets/reel_video_player.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

/// How many neighboring reels (each side) stay loaded as a live
/// [YoutubePlayerController]/WebView around the current one. Keeping this
/// small is what makes a 20-item feed scroll smoothly — only
/// `2 * _kWindowRadius + 1` WebViews ever exist at once, regardless of feed
/// length, instead of one per video.
const int _kWindowRadius = 1;

/// Once fewer than this many loaded items remain after the current one,
/// prefetch the next page in the background so the feed never runs dry.
const int _kPrefetchRemaining = 8;

class _TabSnapshot {
  const _TabSnapshot({
    required this.videos,
    required this.currentIndex,
    required this.hasMore,
  });

  final List<ExploreVideo> videos;
  final int currentIndex;
  final bool hasMore;
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _pageController = PageController();
  List<ExploreVideo> _videos = const [];
  final _controllers = <int, YoutubePlayerController>{};
  final _tabStates = <ExploreMediaType, _TabSnapshot>{};
  ExploreMediaType _mediaType = ExploreMediaType.movies;
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.close();
    }
    super.dispose();
  }

  void _ensureWindow(int center) {
    final desired = <int>{
      for (var i = center - _kWindowRadius; i <= center + _kWindowRadius; i++)
        if (i >= 0 && i < _videos.length) i,
    };

    final outOfWindow = _controllers.keys
        .where((i) => !desired.contains(i))
        .toList();
    for (final i in outOfWindow) {
      _controllers.remove(i)?.close();
    }

    for (final i in desired) {
      _controllers.putIfAbsent(
        i,
        () => YoutubePlayerController.fromVideoId(
          videoId: _videos[i].youtubeId,
          autoPlay: i == center,
          params: YoutubePlayerParams(
            showControls: false,
            showFullscreenButton: false,
            mute: _isMuted,
            loop: kExploreReelLoop,
            playsInline: true,
            enableJavaScript: true,
          ),
        ),
      );
    }
  }

  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pauseVideo();
    _ensureWindow(index);
    _controllers[index]?.playVideo();
    setState(() => _currentIndex = index);

    final remaining = _videos.length - 1 - index;
    if (_hasMore && !_isFetchingMore && remaining <= _kPrefetchRemaining) {
      _loadMoreVideos();
    }
  }

  /// Loads (or reloads) the feed from [exploreVideosProvider] and resets
  /// back to the first reel. Used for the initial load, explicit reloads,
  /// and the first-ever visit to a given media type this session (see
  /// [_switchMediaType], which restores from [_tabStates] instead on repeat
  /// visits). Always invalidates the provider first so this is a genuine
  /// refetch rather than returning Riverpod's cached value for the same
  /// [ExploreMediaType] key.
  Future<void> _loadVideos({ExploreMediaType? mediaType}) async {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();

    final type = mediaType ?? _mediaType;

    setState(() {
      _mediaType = type;
      _isLoading = true;
      _error = null;
      _currentIndex = 0;
    });

    try {
      ref.invalidate(exploreVideosProvider(type));
      final page = await ref
          .read(exploreVideosProvider(type).future)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      setState(() {
        _videos = page.videos;
        _hasMore = page.hasMore;
        _isLoading = false;
      });

      _ensureWindow(0);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (e, stackTrace) {
      debugPrint('ExplorePage._loadVideos failed: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  /// Appends the next page in the background. Failures are logged and
  /// swallowed rather than shown as an error — the current feed keeps
  /// playing either way, and the next swipe-triggered attempt (or the next
  /// reload) can retry.
  Future<void> _loadMoreVideos() async {
    _isFetchingMore = true;
    try {
      final page = await ref
          .read(exploreRepositoryProvider)
          .fetchNextPage(_mediaType);
      if (!mounted) return;
      setState(() {
        _videos = [..._videos, ...page.videos];
        _hasMore = page.hasMore;
      });
    } catch (e, stackTrace) {
      debugPrint('ExplorePage._loadMoreVideos failed: $e\n$stackTrace');
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> _reload() => _loadVideos(mediaType: _mediaType);

  /// Switches Movies/Series, restoring the target tab's previous reel/scroll
  /// position from [_tabStates] instead of reloading from scratch if it's
  /// been visited before this session.
  Future<void> _switchMediaType(ExploreMediaType type) async {
    if (type == _mediaType) return;

    if (_videos.isNotEmpty) {
      _tabStates[_mediaType] = _TabSnapshot(
        videos: _videos,
        currentIndex: _currentIndex,
        hasMore: _hasMore,
      );
    }

    final cached = _tabStates[type];
    if (cached == null) {
      await _loadVideos(mediaType: type);
      return;
    }

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();

    setState(() {
      _mediaType = type;
      _videos = cached.videos;
      _currentIndex = cached.currentIndex;
      _hasMore = cached.hasMore;
      _isLoading = false;
      _error = null;
    });

    _ensureWindow(_currentIndex);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentIndex);
    }
  }

  void _toggleMediaType() => _switchMediaType(_mediaType.next);

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      _controllers[_currentIndex]?.mute();
    } else {
      _controllers[_currentIndex]?.unMute();
    }
  }

  Future<void> _toggleSaved(int movieId, bool isWatchlisted) async {
    final notifier = ref.read(watchlistNotifierProvider.notifier);
    try {
      if (isWatchlisted) {
        await notifier.removeFromWatchlist(movieId);
      } else {
        await notifier.addToWatchlist(movieId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update watchlist: $e')));
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return _MessageContent(
        icon: Icons.error_outline,
        message: 'Could not load videos.\n$_error',
        buttonLabel: 'Retry',
        onPressed: _reload,
      );
    }

    if (_videos.isEmpty) {
      return _MessageContent(
        icon: Icons.movie_filter_outlined,
        message: 'No ${_mediaType.label.toLowerCase()} found right now.',
        buttonLabel: 'Reload',
        onPressed: _reload,
      );
    }

    final watchlist = ref.watch(watchlistNotifierProvider).value ?? {};

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final controller = _controllers[index];

        final movieId = int.tryParse(video.id);
        final isWatchlisted =
            movieId != null && watchlist[movieId]?.accountStatus == 'watchlist';
        return Stack(
          fit: StackFit.expand,
          children: [
            controller == null
                ? _ReelPlaceholder(key: ValueKey(video.id), video: video)
                : ReelVideoPlayer(
                    key: ValueKey(video.id),
                    controller: controller,
                  ),
            // Lives inside the page (not the persistent overlay below) so it
            // slides up/down together with its own video instead of
            // snapping to the new video only once the swipe settles.
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 16,
                    right: 76,
                    bottom: 16,
                    child: ReelInfoPanel(video: video, mediaType: _mediaType),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 16,
                    child: _OverlayIconButton(
                      icon: isWatchlisted
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: isWatchlisted ? Colors.amber : Colors.white,
                      onPressed: movieId == null
                          ? null
                          : () => _toggleSaved(movieId, isWatchlisted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(exploreTabVisibleProvider, (previous, isVisible) {
      if (isVisible) {
        _controllers[_currentIndex]?.playVideo();
      } else {
        for (final controller in _controllers.values) {
          controller.pauseVideo();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildContent(),
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _OverlayIconButton(
                      icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                      onPressed: _toggleMute,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _OverlayIconButton(
                            icon: Icons.refresh,
                            onPressed: _reload,
                          ),
                          const SizedBox(width: 8),
                          _MediaTypeButton(
                            label: _mediaType.label,
                            onPressed: _toggleMediaType,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + message + action button for the error and empty-list states
/// (loading uses a bare spinner instead). Nests inside [ExplorePage]'s own
/// `Scaffold`/overlay rather than being a screen of its own, so the top
/// mute/reload/media-type controls stay visible and tappable through it.
class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

/// Cheap stand-in for a reel outside the live controller window — shows the
/// video's YouTube thumbnail instead of spinning up a WebView, so scrolling
/// past it costs almost nothing.
class _ReelPlaceholder extends StatelessWidget {
  const _ReelPlaceholder({super.key, required this.video});

  final ExploreVideo video;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            'https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _MediaTypeButton extends StatelessWidget {
  const _MediaTypeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
