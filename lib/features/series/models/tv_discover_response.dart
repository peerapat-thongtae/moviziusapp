// Response shape for `/v2/tv/discover`. Ported from the TypeScript
// interfaces in `tv_discover_response.type.ts`, mirroring
// `lib/features/movies/models/movie_discover_response.dart`'s
// defensive-parsing convention: every field falls back to a default instead
// of throwing on a missing/null/wrong-typed value, since a discover/list
// response commonly omits richer detail-only fields (credits, videos,
// external_ids, watch_providers).
//
// `watch_providers` is pre-resolved to the TH region by the backend, so it
// parses directly as one `WatchProviderCountry` (`{ link, flatrate, buy?,
// rent?, ads?, free? }`) rather than a per-country map.
//
// `site`/`type`/`iso_639_1`/`iso_3166_1` on video results stay plain
// `String`s (unlike the movie model's closed enums for the same fields):
// the movie model's enums were inferred from a real JSON sample with known
// literal values, but this .ts file gives no literal union for these
// fields, so a closed enum here would silently drop unknown values.

String _str(dynamic v) => v is String ? v : '';
String? _strOrNull(dynamic v) => v is String ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
int? _intOrNull(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
double _double(dynamic v) => v is num ? v.toDouble() : 0;
bool _bool(dynamic v) => v is bool ? v : false;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

List<String> _strList(dynamic v) =>
    v is List ? v.whereType<String>().toList() : <String>[];

List<int> _intList(dynamic v) =>
    v is List ? v.whereType<num>().map((n) => n.toInt()).toList() : <int>[];

List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is! List) return <T>[];
  return v.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

Map<String, dynamic>? _obj(dynamic v) => v is Map<String, dynamic> ? v : null;

T? _objOrNull<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  final map = _obj(v);
  return map == null ? null : fromJson(map);
}

class TvDiscoverResponse {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<TvShow> results;

  TvDiscoverResponse({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.results,
  });

  factory TvDiscoverResponse.fromJson(Map<String, dynamic> json) {
    return TvDiscoverResponse(
      page: _int(json['page']),
      totalPages: _int(json['total_pages']),
      totalResults: _int(json['total_results']),
      results: _objList(json['results'], TvShow.fromJson),
    );
  }
}

class TvShow {
  final bool adult;
  final String backdropPath;
  final List<CreatedBy> createdBy;
  final List<int> episodeRunTime;
  final String firstAirDate;
  final List<Genre> genres;
  final String homepage;
  final int id;
  final bool inProduction;
  final List<String> languages;
  final String lastAirDate;
  final Episode? lastEpisodeToAir;
  final String name;
  final Episode? nextEpisodeToAir;
  final List<Network> networks;
  final int numberOfEpisodes;
  final int numberOfSeasons;
  final List<String> originCountry;
  final String originalLanguage;
  final String originalName;
  final String overview;
  final double popularity;
  final String posterPath;
  final List<ProductionCompany> productionCompanies;
  final List<ProductionCountry> productionCountries;
  final List<Season> seasons;
  final bool softcore;
  final List<SpokenLanguage> spokenLanguages;
  final String status;
  final String tagline;
  final String type;
  final double voteAverage;
  final int voteCount;
  final Credits? credits;
  final ExternalIds? externalIds;
  final Videos? videos;
  final String mediaType;
  final String imdbId;
  final WatchProviderCountry? watchProviders;

  TvShow({
    required this.adult,
    required this.backdropPath,
    required this.createdBy,
    required this.episodeRunTime,
    required this.firstAirDate,
    required this.genres,
    required this.homepage,
    required this.id,
    required this.inProduction,
    required this.languages,
    required this.lastAirDate,
    required this.lastEpisodeToAir,
    required this.name,
    required this.nextEpisodeToAir,
    required this.networks,
    required this.numberOfEpisodes,
    required this.numberOfSeasons,
    required this.originCountry,
    required this.originalLanguage,
    required this.originalName,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.productionCompanies,
    required this.productionCountries,
    required this.seasons,
    required this.softcore,
    required this.spokenLanguages,
    required this.status,
    required this.tagline,
    required this.type,
    required this.voteAverage,
    required this.voteCount,
    required this.credits,
    required this.externalIds,
    required this.videos,
    required this.mediaType,
    required this.imdbId,
    required this.watchProviders,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      adult: _bool(json['adult']),
      backdropPath: _str(json['backdrop_path']),
      createdBy: _objList(json['created_by'], CreatedBy.fromJson),
      episodeRunTime: _intList(json['episode_run_time']),
      firstAirDate: _str(json['first_air_date']),
      genres: _objList(json['genres'], Genre.fromJson),
      homepage: _str(json['homepage']),
      id: _int(json['id']),
      inProduction: _bool(json['in_production']),
      languages: _strList(json['languages']),
      lastAirDate: _str(json['last_air_date']),
      lastEpisodeToAir: _objOrNull(
        json['last_episode_to_air'],
        Episode.fromJson,
      ),
      name: _str(json['name']),
      nextEpisodeToAir: _objOrNull(
        json['next_episode_to_air'],
        Episode.fromJson,
      ),
      networks: _objList(json['networks'], Network.fromJson),
      numberOfEpisodes: _int(json['number_of_episodes']),
      numberOfSeasons: _int(json['number_of_seasons']),
      originCountry: _strList(json['origin_country']),
      originalLanguage: _str(json['original_language']),
      originalName: _str(json['original_name']),
      overview: _str(json['overview']),
      popularity: _double(json['popularity']),
      posterPath: _str(json['poster_path']),
      productionCompanies: _objList(
        json['production_companies'],
        ProductionCompany.fromJson,
      ),
      productionCountries: _objList(
        json['production_countries'],
        ProductionCountry.fromJson,
      ),
      seasons: _objList(json['seasons'], Season.fromJson),
      softcore: _bool(json['softcore']),
      spokenLanguages: _objList(
        json['spoken_languages'],
        SpokenLanguage.fromJson,
      ),
      status: _str(json['status']),
      tagline: _str(json['tagline']),
      type: _str(json['type']),
      voteAverage: _double(json['vote_average']),
      voteCount: _int(json['vote_count']),
      credits: _objOrNull(json['credits'], Credits.fromJson),
      externalIds: _objOrNull(json['external_ids'], ExternalIds.fromJson),
      videos: _objOrNull(json['videos'], Videos.fromJson),
      mediaType: _str(json['media_type']),
      imdbId: _str(json['imdb_id']),
      watchProviders: _objOrNull(
        json['watch_providers'],
        WatchProviderCountry.fromJson,
      ),
    );
  }

  /// The show's creator, preferring TMDB's `created_by` (only reliably
  /// present on the true `/tv/:id` detail response) and falling back to an
  /// Executive Producer credit from [credits] — mirrors `Movie.director`'s
  /// crew-based derivation, which is why movies don't hit this "Unknown"
  /// class of bug the way TV shows can.
  String? get creator {
    if (createdBy.isNotEmpty) return createdBy.first.name;
    for (final c in credits?.crew ?? const []) {
      if (c.job == 'Executive Producer') return c.name;
    }
    return null;
  }
}

class CreatedBy {
  final int id;
  final String creditId;
  final String name;
  final String originalName;
  final int gender;
  final String? profilePath;

  CreatedBy({
    required this.id,
    required this.creditId,
    required this.name,
    required this.originalName,
    required this.gender,
    this.profilePath,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: _int(json['id']),
      creditId: _str(json['credit_id']),
      name: _str(json['name']),
      originalName: _str(json['original_name']),
      gender: _int(json['gender']),
      profilePath: _strOrNull(json['profile_path']),
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: _int(json['id']), name: _str(json['name']));
}

/// Merges the TS `LastEpisodeToAir`/`NextEpisodeToAir` interfaces into one
/// shape — the only difference between them is that `runtime`/`still_path`
/// are optional on the latter, which a nullable field already covers.
class Episode {
  final int id;
  final String name;
  final String overview;
  final double voteAverage;
  final int voteCount;
  final String airDate;
  final int episodeNumber;
  final String episodeType;
  final String productionCode;
  final int? runtime;
  final int seasonNumber;
  final int showId;
  final String? stillPath;

  Episode({
    required this.id,
    required this.name,
    required this.overview,
    required this.voteAverage,
    required this.voteCount,
    required this.airDate,
    required this.episodeNumber,
    required this.episodeType,
    required this.productionCode,
    this.runtime,
    required this.seasonNumber,
    required this.showId,
    this.stillPath,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: _int(json['id']),
      name: _str(json['name']),
      overview: _str(json['overview']),
      voteAverage: _double(json['vote_average']),
      voteCount: _int(json['vote_count']),
      airDate: _str(json['air_date']),
      episodeNumber: _int(json['episode_number']),
      episodeType: _str(json['episode_type']),
      productionCode: _str(json['production_code']),
      runtime: _intOrNull(json['runtime']),
      seasonNumber: _int(json['season_number']),
      showId: _int(json['show_id']),
      stillPath: _strOrNull(json['still_path']),
    );
  }
}

class Network {
  final int id;
  final String logoPath;
  final String name;
  final String originCountry;

  Network({
    required this.id,
    required this.logoPath,
    required this.name,
    required this.originCountry,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      id: _int(json['id']),
      logoPath: _str(json['logo_path']),
      name: _str(json['name']),
      originCountry: _str(json['origin_country']),
    );
  }
}

class ProductionCompany {
  final int id;
  final String? logoPath;
  final String name;
  final String originCountry;

  ProductionCompany({
    required this.id,
    this.logoPath,
    required this.name,
    required this.originCountry,
  });

  factory ProductionCompany.fromJson(Map<String, dynamic> json) {
    return ProductionCompany(
      id: _int(json['id']),
      logoPath: _strOrNull(json['logo_path']),
      name: _str(json['name']),
      originCountry: _str(json['origin_country']),
    );
  }
}

class ProductionCountry {
  final String iso31661;
  final String name;

  ProductionCountry({required this.iso31661, required this.name});

  factory ProductionCountry.fromJson(Map<String, dynamic> json) {
    return ProductionCountry(
      iso31661: _str(json['iso_3166_1']),
      name: _str(json['name']),
    );
  }
}

class Season {
  final String? airDate;
  final int episodeCount;
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final int seasonNumber;
  final double voteAverage;

  Season({
    this.airDate,
    required this.episodeCount,
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    required this.seasonNumber,
    required this.voteAverage,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      airDate: _strOrNull(json['air_date']),
      episodeCount: _int(json['episode_count']),
      id: _int(json['id']),
      name: _str(json['name']),
      overview: _str(json['overview']),
      posterPath: _strOrNull(json['poster_path']),
      seasonNumber: _int(json['season_number']),
      voteAverage: _double(json['vote_average']),
    );
  }
}

class SpokenLanguage {
  final String englishName;
  final String iso6391;
  final String name;

  SpokenLanguage({
    required this.englishName,
    required this.iso6391,
    required this.name,
  });

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) {
    return SpokenLanguage(
      englishName: _str(json['english_name']),
      iso6391: _str(json['iso_639_1']),
      name: _str(json['name']),
    );
  }
}

class Credits {
  final List<CastMember> cast;
  final List<CastMember> crew;

  Credits({required this.cast, required this.crew});

  factory Credits.fromJson(Map<String, dynamic> json) {
    return Credits(
      cast: _objList(json['cast'], CastMember.fromJson),
      crew: _objList(json['crew'], CastMember.fromJson),
    );
  }
}

/// Merges the TS `Cast`/`Crew` interfaces into one shape (mirrors
/// movie_discover_response.dart's `Cast` class) since the only difference
/// between the two is which optional fields are populated: `character`/
/// `order` for cast, `department`/`job` for crew.
class CastMember {
  final bool adult;
  final int gender;
  final int id;
  final String knownForDepartment;
  final String name;
  final String originalName;
  final double popularity;
  final String? profilePath;
  final String? character;
  final String creditId;
  final int? order;
  final String? department;
  final String? job;

  CastMember({
    required this.adult,
    required this.gender,
    required this.id,
    required this.knownForDepartment,
    required this.name,
    required this.originalName,
    required this.popularity,
    this.profilePath,
    this.character,
    required this.creditId,
    this.order,
    this.department,
    this.job,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      adult: _bool(json['adult']),
      gender: _int(json['gender']),
      id: _int(json['id']),
      knownForDepartment: _str(json['known_for_department']),
      name: _str(json['name']),
      originalName: _str(json['original_name']),
      popularity: _double(json['popularity']),
      profilePath: _strOrNull(json['profile_path']),
      character: _strOrNull(json['character']),
      creditId: _str(json['credit_id']),
      order: _intOrNull(json['order']),
      department: _strOrNull(json['department']),
      job: _strOrNull(json['job']),
    );
  }
}

class ExternalIds {
  final String imdbId;
  final String? freebaseMid;
  final String? freebaseId;
  final int? tvdbId;
  final int? tvrageId;
  final String? wikidataId;
  final String? facebookId;
  final String? instagramId;
  final String? twitterId;

  ExternalIds({
    required this.imdbId,
    this.freebaseMid,
    this.freebaseId,
    this.tvdbId,
    this.tvrageId,
    this.wikidataId,
    this.facebookId,
    this.instagramId,
    this.twitterId,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) {
    return ExternalIds(
      imdbId: _str(json['imdb_id']),
      freebaseMid: _strOrNull(json['freebase_mid']),
      freebaseId: _strOrNull(json['freebase_id']),
      tvdbId: _intOrNull(json['tvdb_id']),
      tvrageId: _intOrNull(json['tvrage_id']),
      wikidataId: _strOrNull(json['wikidata_id']),
      facebookId: _strOrNull(json['facebook_id']),
      instagramId: _strOrNull(json['instagram_id']),
      twitterId: _strOrNull(json['twitter_id']),
    );
  }
}

class Videos {
  final List<SeriesVideoResult> results;

  Videos({required this.results});

  factory Videos.fromJson(Map<String, dynamic> json) {
    return Videos(
      results: _objList(json['results'], SeriesVideoResult.fromJson),
    );
  }
}

class SeriesVideoResult {
  final String iso6391;
  final String iso31661;
  final String name;
  final String key;
  final String site;
  final int size;
  final String type;
  final bool official;
  final String id;
  final DateTime? publishedAt;

  SeriesVideoResult({
    required this.iso6391,
    required this.iso31661,
    required this.name,
    required this.key,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.id,
    required this.publishedAt,
  });

  factory SeriesVideoResult.fromJson(Map<String, dynamic> json) {
    return SeriesVideoResult(
      iso6391: _str(json['iso_639_1']),
      iso31661: _str(json['iso_3166_1']),
      name: _str(json['name']),
      key: _str(json['key']),
      site: _str(json['site']),
      size: _int(json['size']),
      type: _str(json['type']),
      official: _bool(json['official']),
      id: _str(json['id']),
      publishedAt: _date(json['published_at']),
    );
  }
}

class WatchProviderCountry {
  final String link;
  final List<Flatrate>? flatrate;
  final List<Flatrate>? rent;
  final List<Flatrate>? buy;
  final List<Flatrate>? ads;
  final List<Flatrate>? free;

  WatchProviderCountry({
    required this.link,
    this.flatrate,
    this.rent,
    this.buy,
    this.ads,
    this.free,
  });

  factory WatchProviderCountry.fromJson(Map<String, dynamic> json) {
    List<Flatrate>? parseOptional(String key) =>
        json[key] == null ? null : _objList(json[key], Flatrate.fromJson);

    return WatchProviderCountry(
      link: _str(json['link']),
      flatrate: parseOptional('flatrate'),
      rent: parseOptional('rent'),
      buy: parseOptional('buy'),
      ads: parseOptional('ads'),
      free: parseOptional('free'),
    );
  }
}

class Flatrate {
  final String logoPath;
  final int providerId;
  final String providerName;
  final int displayPriority;

  Flatrate({
    required this.logoPath,
    required this.providerId,
    required this.providerName,
    required this.displayPriority,
  });

  factory Flatrate.fromJson(Map<String, dynamic> json) {
    return Flatrate(
      logoPath: _str(json['logo_path']),
      providerId: _int(json['provider_id']),
      providerName: _str(json['provider_name']),
      displayPriority: _int(json['display_priority']),
    );
  }
}
