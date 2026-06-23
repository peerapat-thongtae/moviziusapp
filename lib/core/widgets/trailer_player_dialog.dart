import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'overlay_icon_button.dart';

/// Opens a full-screen modal playing the YouTube trailer for [youtubeKey].
/// Used by the movie/series detail pages' backdrop play button.
Future<void> showTrailerPlayer(BuildContext context, String youtubeKey) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) => _TrailerPlayerDialog(youtubeKey: youtubeKey),
  );
}

class _TrailerPlayerDialog extends StatefulWidget {
  const _TrailerPlayerDialog({required this.youtubeKey});

  final String youtubeKey;

  @override
  State<_TrailerPlayerDialog> createState() => _TrailerPlayerDialogState();
}

class _TrailerPlayerDialogState extends State<_TrailerPlayerDialog> {
  late final _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.youtubeKey,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showControls: true,
      showFullscreenButton: true,
      playsInline: true,
      enableJavaScript: true,
    ),
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: YoutubePlayer(
              controller: _controller,
              backgroundColor: Colors.black,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: OverlayIconButton(
                icon: Icons.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
