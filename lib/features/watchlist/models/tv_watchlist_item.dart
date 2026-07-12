// Response shape for `/v2/tv` (the TV watchlist). Ported from the TypeScript
// interfaces in `tv_watchlist.type.ts`, following the defensive-parsing
// convention used by `lib/features/series/models/tv_discover_response.dart`:
// every field falls back to a default instead of throwing on a
// missing/null/wrong-typed value, so a list response can omit richer
// detail-only fields without breaking parsing.
//
// The TS `MaxWatchedEp` is the same shape as `EpisodeWatched` (with a
// required `watched_at`), so both are parsed into [EpisodeWatched]. The TS
// `NextEpisodeToAir` and `LastEpisodeToAir` are identical, so both are parsed
// into [TvAiredEpisode].
//
// Scalar/collection fields default (not require) in the constructor so the
// provider can build a minimal item for optimistic add/watched updates
// without supplying the full detail payload.

String _str(dynamic v) => v is String ? v : '';
String? _strOrNull(dynamic v) => v is String ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
double _double(dynamic v) => v is num ? v.toDouble() : 0;
double? _doubleOrNull(dynamic v) => v is num ? v.toDouble() : null;
bool _bool(dynamic v) => v is bool ? v : false;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

List<int> _intList(dynamic v) =>
    v is List ? v.whereType<num>().map((n) => n.toInt()).toList() : <int>[];

List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is! List) return <T>[];
  return v.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

T? _objOrNull<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) =>
    v is Map<String, dynamic> ? fromJson(v) : null;

class TvWatchlistItem {
  const TvWatchlistItem({
    required this.id,
    this.userId = '',
    this.episodeWatched = const [],
    this.watchlistedAt,
    this.maxWatchedEp,
    this.countWatched = 0,
    this.accountStatus = '',
    this.latestState = '',
    this.name = '',
    this.mediaType = 'tv',
    this.isAnime = false,
    this.voteAverage = 0,
    this.voteCount = 0,
    this.numberOfEpisodes = 0,
    this.numberOfSeasons = 0,
    this.nextEpisodeToAir,
    this.lastEpisodeToAir,
    this.seasons = const [],
    this.watchedSeasons = const [],
    this.latestWatched,
    this.rating,
  });

  final int id;
  final String userId;
  final List<EpisodeWatched> episodeWatched;
  final DateTime? watchlistedAt;
  final EpisodeWatched? maxWatchedEp;
  final int countWatched;
  final String accountStatus;
  final String latestState;
  final String name;
  final String mediaType;
  final bool isAnime;
  final double voteAverage;
  final int voteCount;
  final int numberOfEpisodes;
  final int numberOfSeasons;
  final TvAiredEpisode? nextEpisodeToAir;
  final TvAiredEpisode? lastEpisodeToAir;
  final List<TvWatchlistSeason> seasons;
  final List<int> watchedSeasons;
  final String? latestWatched;
  final double? rating;

  TvWatchlistItem copyWith({
    int? id,
    String? userId,
    List<EpisodeWatched>? episodeWatched,
    DateTime? watchlistedAt,
    EpisodeWatched? maxWatchedEp,
    int? countWatched,
    String? accountStatus,
    String? latestState,
    String? name,
    String? mediaType,
    bool? isAnime,
    double? voteAverage,
    int? voteCount,
    int? numberOfEpisodes,
    int? numberOfSeasons,
    TvAiredEpisode? nextEpisodeToAir,
    TvAiredEpisode? lastEpisodeToAir,
    List<TvWatchlistSeason>? seasons,
    List<int>? watchedSeasons,
    String? latestWatched,
    double? rating,
  }) {
    return TvWatchlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      episodeWatched: episodeWatched ?? this.episodeWatched,
      watchlistedAt: watchlistedAt ?? this.watchlistedAt,
      maxWatchedEp: maxWatchedEp ?? this.maxWatchedEp,
      countWatched: countWatched ?? this.countWatched,
      accountStatus: accountStatus ?? this.accountStatus,
      latestState: latestState ?? this.latestState,
      name: name ?? this.name,
      mediaType: mediaType ?? this.mediaType,
      isAnime: isAnime ?? this.isAnime,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      nextEpisodeToAir: nextEpisodeToAir ?? this.nextEpisodeToAir,
      lastEpisodeToAir: lastEpisodeToAir ?? this.lastEpisodeToAir,
      seasons: seasons ?? this.seasons,
      watchedSeasons: watchedSeasons ?? this.watchedSeasons,
      latestWatched: latestWatched ?? this.latestWatched,
      rating: rating ?? this.rating,
    );
  }

  factory TvWatchlistItem.fromJson(Map<String, dynamic> json) {
    return TvWatchlistItem(
      id: _int(json['id']),
      userId: _str(json['user_id']),
      episodeWatched: _objList(json['episode_watched'], EpisodeWatched.fromJson),
      watchlistedAt: _date(json['watchlisted_at']),
      maxWatchedEp: _objOrNull(json['max_watched_ep'], EpisodeWatched.fromJson),
      countWatched: _int(json['count_watched']),
      accountStatus: _str(json['account_status']),
      latestState: _str(json['latest_state']),
      name: _str(json['name']),
      mediaType: json['media_type'] is String ? json['media_type'] : 'tv',
      isAnime: _bool(json['is_anime']),
      voteAverage: _double(json['vote_average']),
      voteCount: _int(json['vote_count']),
      numberOfEpisodes: _int(json['number_of_episodes']),
      numberOfSeasons: _int(json['number_of_seasons']),
      nextEpisodeToAir:
          _objOrNull(json['next_episode_to_air'], TvAiredEpisode.fromJson),
      lastEpisodeToAir:
          _objOrNull(json['last_episode_to_air'], TvAiredEpisode.fromJson),
      seasons: _objList(json['seasons'], TvWatchlistSeason.fromJson),
      watchedSeasons: _intList(json['watched_seasons']),
      latestWatched: _strOrNull(json['latest_watched']),
      rating: _doubleOrNull(json['rating']),
    );
  }
}

class EpisodeWatched {
  const EpisodeWatched({
    required this.episodeId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.watchedAt,
  });

  final int episodeId;
  final int seasonNumber;
  final int episodeNumber;
  final DateTime? watchedAt;

  factory EpisodeWatched.fromJson(Map<String, dynamic> json) {
    return EpisodeWatched(
      episodeId: _int(json['episode_id']),
      seasonNumber: _int(json['season_number']),
      episodeNumber: _int(json['episode_number']),
      watchedAt: _date(json['watched_at']),
    );
  }
}

class TvAiredEpisode {
  const TvAiredEpisode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    this.airDate,
    this.episodeType = '',
  });

  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final DateTime? airDate;
  final String episodeType;

  factory TvAiredEpisode.fromJson(Map<String, dynamic> json) {
    return TvAiredEpisode(
      id: _int(json['id']),
      episodeNumber: _int(json['episode_number']),
      seasonNumber: _int(json['season_number']),
      airDate: _date(json['air_date']),
      episodeType: _str(json['episode_type']),
    );
  }
}

class TvWatchlistSeason {
  const TvWatchlistSeason({
    required this.id,
    required this.seasonNumber,
    this.name = '',
    this.episodeCount = 0,
    this.airDate,
  });

  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final DateTime? airDate;

  factory TvWatchlistSeason.fromJson(Map<String, dynamic> json) {
    return TvWatchlistSeason(
      id: _int(json['id']),
      seasonNumber: _int(json['season_number']),
      name: _str(json['name']),
      episodeCount: _int(json['episode_count']),
      airDate: _date(json['air_date']),
    );
  }
}
