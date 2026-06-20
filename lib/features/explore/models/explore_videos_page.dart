import 'explore_video.dart';

/// A page of [ExploreVideo]s plus whether more can be fetched after it.
class ExploreVideosPage {
  final List<ExploreVideo> videos;
  final bool hasMore;

  const ExploreVideosPage({required this.videos, required this.hasMore});
}
