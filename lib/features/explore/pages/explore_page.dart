import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/explore_media_type.dart';
import '../models/explore_video.dart';
import '../providers/explore_videos_provider.dart';
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

class _ExplorePageState extends ConsumerState<ExplorePage> {
  final _pageController = PageController();
  late List<ExploreVideo> _videos;
  final _controllers = <int, YoutubePlayerController>{};
  ExploreMediaType _mediaType = ExploreMediaType.movies;
  int _currentIndex = 0;
  bool _isMuted = false;
  final _savedVideoIds = <String>{};

  @override
  void initState() {
    super.initState();
    _videos = ref.read(exploreVideosProvider(_mediaType));
    _ensureWindow(_currentIndex);
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
  }

  /// Resets the feed back to the first reel and reloads its data.
  /// Also used when switching media type, since that's effectively a
  /// reload against a different mock dataset.
  void _reload({ExploreMediaType? mediaType}) {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();

    setState(() {
      _mediaType = mediaType ?? _mediaType;
      _videos = ref.read(exploreVideosProvider(_mediaType));
      _currentIndex = 0;
    });

    _ensureWindow(0);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _toggleMediaType() => _reload(mediaType: _mediaType.next);

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      _controllers[_currentIndex]?.mute();
    } else {
      _controllers[_currentIndex]?.unMute();
    }
  }

  void _toggleSaved(String videoId) {
    setState(() {
      if (_savedVideoIds.contains(videoId)) {
        _savedVideoIds.remove(videoId);
      } else {
        _savedVideoIds.add(videoId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _savedVideoIds.contains(videoId)
              ? 'Added to watchlist (mock)'
              : 'Removed from watchlist (mock)',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final controller = _controllers[index];
              if (controller == null) {
                return _ReelPlaceholder(
                  key: ValueKey(_videos[index].id),
                  video: _videos[index],
                );
              }
              return ReelVideoPlayer(
                key: ValueKey(_videos[index].id),
                controller: controller,
              );
            },
          ),
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
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '${_currentIndex + 1}/${_videos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 64,
                    child: _OverlayIconButton(
                      icon: _savedVideoIds.contains(_videos[_currentIndex].id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      onPressed: () => _toggleSaved(_videos[_currentIndex].id),
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
  const _OverlayIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
