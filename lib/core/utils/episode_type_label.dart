/// Maps an episode's TMDB `episode_type` (plus its episode number, since
/// `episode_type` isn't reliably populated as `premiere` for every season's
/// first episode) to a user-facing badge label. Only finales and season
/// premieres are worth calling out; everything else gets no badge.
String? episodeTypeLabel(String episodeType, int episodeNumber) {
  if (episodeType == 'finale') return 'Season Finale';
  if (episodeType == 'premiere' || episodeNumber == 1) {
    return 'Season Premiere';
  }
  return null;
}
