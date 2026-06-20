import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Default end-of-video behavior for reels: replay in place.
/// Flip to `false` (and listen to `controller.videoStateStream` for
/// `PlayerState.ended`) to auto-advance to the next reel instead.
const bool kExploreReelLoop = true;

/// Renders a single reel's [YoutubePlayer].
///
/// The controller is owned by the parent (not this widget) so play/pause
/// state survives independently of [PageView]'s build cycle. This widget
/// stays alive ([AutomaticKeepAliveClientMixin]) once built so the native
/// WebView backing the controller isn't torn down when the page scrolls
/// outside [PageView]'s cache range — without that, swiping back to an
/// already-visited reel would resume a controller with no WebView left to
/// control.
class ReelVideoPlayer extends StatefulWidget {
  const ReelVideoPlayer({super.key, required this.controller});

  final YoutubePlayerController controller;

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Colors.black,
      child: Center(
        child: IgnorePointer(
          child: YoutubePlayer(
            controller: widget.controller,
            backgroundColor: Colors.black,
            enableFullScreenOnVerticalDrag: false,
            autoFullScreen: false,
          ),
        ),
      ),
    );
  }
}
