// ignore_for_file: constant_identifier_names
// Enum values intentionally mirror the original schema's casing (e.g.
// YOU_TUBE, COSTUME_MAKE_UP) rather than Dart's lowerCamelCase convention.

// Response shape for `/v2/movie/discover`. Ported from a real backend
// response sample (root-level `movie_type.dart` scratch file); JSON keys are
// inferred as snake_case of each field name, with two exceptions that mirror
// TMDB's `append_to_response` convention: `watchProviders` -> "watch/providers"
// and `releaseDateTh` -> "release_dates_th".
//
// `watch/providers` is pre-resolved to the TH region by the backend, so it
// parses directly as one `WatchProviderCountry` (`{ link, flatrate, buy?,
// rent?, ads?, free? }`) rather than a per-country map.
//
// Every field is parsed defensively (missing/null/wrong-typed values fall
// back to a default instead of throwing) since a discover/list endpoint
// commonly omits the richer detail-only fields (casts, videos, budget, etc.)
// that a single-movie detail endpoint would include.

String _str(dynamic v) => v is String ? v : '';
String? _strOrNull(dynamic v) => v is String ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
int? _intOrNull(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
double _double(dynamic v) => v is num ? v.toDouble() : 0;
bool _bool(dynamic v) => v is bool ? v : false;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

List<String> _strList(dynamic v) =>
    v is List ? v.whereType<String>().toList() : <String>[];

List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is! List) return <T>[];
  return v.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

Map<String, dynamic>? _obj(dynamic v) => v is Map<String, dynamic> ? v : null;

T? _objOrNull<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  final map = _obj(v);
  return map == null ? null : fromJson(map);
}

class MovieDiscoverResponse {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<Movie> results;

  MovieDiscoverResponse({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.results,
  });

  factory MovieDiscoverResponse.fromJson(Map<String, dynamic> json) {
    return MovieDiscoverResponse(
      page: _int(json['page']),
      totalPages: _int(json['total_pages']),
      totalResults: _int(json['total_results']),
      results: _objList(json['results'], Movie.fromJson),
    );
  }
}

class Movie {
  final bool adult;
  final String backdropPath;
  final BelongsToCollection? belongsToCollection;
  final int budget;
  final List<Genre> genres;
  final String homepage;
  final int id;
  final String imdbId;
  final List<String> originCountry;
  final String originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String posterPath;
  final List<ProductionCompany> productionCompanies;
  final List<ProductionCountry> productionCountries;
  final DateTime? releaseDate;
  final int revenue;
  final int runtime;
  final bool softcore;
  final List<SpokenLanguage> spokenLanguages;
  final String status;
  final String tagline;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;
  final ExternalIds? externalIds;
  final Casts? casts;
  final Videos? videos;
  final ReleaseDates? releaseDates;
  final String mediaType;
  final WatchProviderCountry? watchProviders;
  final List<ReleaseDate> releaseDateTh;

  Movie({
    required this.adult,
    required this.backdropPath,
    required this.belongsToCollection,
    required this.budget,
    required this.genres,
    required this.homepage,
    required this.id,
    required this.imdbId,
    required this.originCountry,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.productionCompanies,
    required this.productionCountries,
    required this.releaseDate,
    required this.revenue,
    required this.runtime,
    required this.softcore,
    required this.spokenLanguages,
    required this.status,
    required this.tagline,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
    required this.externalIds,
    required this.casts,
    required this.videos,
    required this.releaseDates,
    required this.mediaType,
    required this.watchProviders,
    required this.releaseDateTh,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      adult: _bool(json['adult']),
      backdropPath: _str(json['backdrop_path']),
      belongsToCollection: _objOrNull(
        json['belongs_to_collection'],
        BelongsToCollection.fromJson,
      ),
      budget: _int(json['budget']),
      genres: _objList(json['genres'], Genre.fromJson),
      homepage: _str(json['homepage']),
      id: _int(json['id']),
      imdbId: _str(json['imdb_id']),
      originCountry: _strList(json['origin_country']),
      originalLanguage: _str(json['original_language']),
      originalTitle: _str(json['original_title']),
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
      releaseDate: _date(json['release_date']),
      revenue: _int(json['revenue']),
      runtime: _int(json['runtime']),
      softcore: _bool(json['softcore']),
      spokenLanguages: _objList(
        json['spoken_languages'],
        SpokenLanguage.fromJson,
      ),
      status: _str(json['status']),
      tagline: _str(json['tagline']),
      title: _str(json['title']),
      video: _bool(json['video']),
      voteAverage: _double(json['vote_average']),
      voteCount: _int(json['vote_count']),
      externalIds: _objOrNull(json['external_ids'], ExternalIds.fromJson),
      casts: _objOrNull(json['casts'], Casts.fromJson),
      videos: _objOrNull(json['videos'], Videos.fromJson),
      releaseDates: _objOrNull(json['release_dates'], ReleaseDates.fromJson),
      mediaType: _str(json['media_type']),
      watchProviders: _objOrNull(
        json['watch_providers'],
        WatchProviderCountry.fromJson,
      ),
      releaseDateTh: _objList(json['release_dates_th'], ReleaseDate.fromJson),
    );
  }

  String? get director {
    for (final c in casts?.crew ?? const []) {
      if (c.job == 'Director') return c.name;
    }
    return null;
  }

  /// TH-region release date if TMDB provided one, else the global
  /// [releaseDate].
  DateTime? get effectiveReleaseDate =>
      (releaseDateTh.isNotEmpty ? releaseDateTh.first.releaseDate : null) ??
      releaseDate;
}

class BelongsToCollection {
  final int id;
  final String name;
  final String posterPath;
  final String backdropPath;

  BelongsToCollection({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
  });

  factory BelongsToCollection.fromJson(Map<String, dynamic> json) {
    return BelongsToCollection(
      id: _int(json['id']),
      name: _str(json['name']),
      posterPath: _str(json['poster_path']),
      backdropPath: _str(json['backdrop_path']),
    );
  }
}

class Casts {
  final List<Cast> cast;
  final List<Cast> crew;

  Casts({required this.cast, required this.crew});

  factory Casts.fromJson(Map<String, dynamic> json) {
    return Casts(
      cast: _objList(json['cast'], Cast.fromJson),
      crew: _objList(json['crew'], Cast.fromJson),
    );
  }
}

class Cast {
  final bool adult;
  final int gender;
  final int id;
  final Department knownForDepartment;
  final String name;
  final String originalName;
  final double popularity;
  final String? profilePath;
  final int? castId;
  final String? character;
  final String creditId;
  final int? order;
  final Department? department;
  final String? job;

  Cast({
    required this.adult,
    required this.gender,
    required this.id,
    required this.knownForDepartment,
    required this.name,
    required this.originalName,
    required this.popularity,
    required this.profilePath,
    this.castId,
    this.character,
    required this.creditId,
    this.order,
    this.department,
    this.job,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      adult: _bool(json['adult']),
      gender: _int(json['gender']),
      id: _int(json['id']),
      knownForDepartment: Department.fromJson(
        _str(json['known_for_department']),
      ),
      name: _str(json['name']),
      originalName: _str(json['original_name']),
      popularity: _double(json['popularity']),
      profilePath: _strOrNull(json['profile_path']),
      castId: _intOrNull(json['cast_id']),
      character: _strOrNull(json['character']),
      creditId: _str(json['credit_id']),
      order: _intOrNull(json['order']),
      department: json['department'] == null
          ? null
          : Department.fromJson(_str(json['department'])),
      job: _strOrNull(json['job']),
    );
  }
}

enum Department {
  ACTING,
  ART,
  CAMERA,
  COSTUME_MAKE_UP,
  CREW,
  DIRECTING,
  EDITING,
  LIGHTING,
  PRODUCTION,
  SOUND,
  VISUAL_EFFECTS,
  WRITING,
  UNKNOWN;

  static Department fromJson(String value) => switch (value) {
    'Acting' => Department.ACTING,
    'Art' => Department.ART,
    'Camera' => Department.CAMERA,
    'Costume & Make-Up' => Department.COSTUME_MAKE_UP,
    'Crew' => Department.CREW,
    'Directing' => Department.DIRECTING,
    'Editing' => Department.EDITING,
    'Lighting' => Department.LIGHTING,
    'Production' => Department.PRODUCTION,
    'Sound' => Department.SOUND,
    'Visual Effects' => Department.VISUAL_EFFECTS,
    'Writing' => Department.WRITING,
    _ => Department.UNKNOWN,
  };
}

class ExternalIds {
  final String imdbId;
  final String wikidataId;
  final String? facebookId;
  final String? instagramId;
  final String? twitterId;

  ExternalIds({
    required this.imdbId,
    required this.wikidataId,
    required this.facebookId,
    required this.instagramId,
    required this.twitterId,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) {
    return ExternalIds(
      imdbId: _str(json['imdb_id']),
      wikidataId: _str(json['wikidata_id']),
      facebookId: _strOrNull(json['facebook_id']),
      instagramId: _strOrNull(json['instagram_id']),
      twitterId: _strOrNull(json['twitter_id']),
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: _int(json['id']), name: _str(json['name']));
  }
}

class ProductionCompany {
  final int id;
  final String? logoPath;
  final String name;
  final String originCountry;

  ProductionCompany({
    required this.id,
    required this.logoPath,
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

class ReleaseDate {
  final String certification;
  final List<String> descriptors;
  final ReleaseDateThIso6391 iso6391;
  final String note;
  final DateTime? releaseDate;
  final int type;

  ReleaseDate({
    required this.certification,
    required this.descriptors,
    required this.iso6391,
    required this.note,
    required this.releaseDate,
    required this.type,
  });

  factory ReleaseDate.fromJson(Map<String, dynamic> json) {
    return ReleaseDate(
      certification: _str(json['certification']),
      descriptors: _strList(json['descriptors']),
      iso6391: ReleaseDateThIso6391.fromJson(_str(json['iso_639_1'])),
      note: _str(json['note']),
      releaseDate: _date(json['release_date']),
      type: _int(json['type']),
    );
  }
}

enum ReleaseDateThIso6391 {
  DE,
  EMPTY,
  FR,
  IT,
  JA,
  SK;

  static ReleaseDateThIso6391 fromJson(String value) => switch (value) {
    'de' => ReleaseDateThIso6391.DE,
    'fr' => ReleaseDateThIso6391.FR,
    'it' => ReleaseDateThIso6391.IT,
    'ja' => ReleaseDateThIso6391.JA,
    'sk' => ReleaseDateThIso6391.SK,
    _ => ReleaseDateThIso6391.EMPTY,
  };
}

class ReleaseDates {
  final List<ReleaseDatesResult> results;

  ReleaseDates({required this.results});

  factory ReleaseDates.fromJson(Map<String, dynamic> json) {
    return ReleaseDates(
      results: _objList(json['results'], ReleaseDatesResult.fromJson),
    );
  }
}

class ReleaseDatesResult {
  final String iso31661;
  final List<ReleaseDate> releaseDates;

  ReleaseDatesResult({required this.iso31661, required this.releaseDates});

  factory ReleaseDatesResult.fromJson(Map<String, dynamic> json) {
    return ReleaseDatesResult(
      iso31661: _str(json['iso_3166_1']),
      releaseDates: _objList(json['release_dates'], ReleaseDate.fromJson),
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

class Videos {
  final List<VideosResult> results;

  Videos({required this.results});

  factory Videos.fromJson(Map<String, dynamic> json) {
    return Videos(results: _objList(json['results'], VideosResult.fromJson));
  }
}

class VideosResult {
  final ResultIso6391 iso6391;
  final Iso31661 iso31661;
  final String name;
  final String key;
  final Site site;
  final int size;
  final VideoType type;
  final bool official;
  final String id;
  final DateTime? publishedAt;

  VideosResult({
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

  factory VideosResult.fromJson(Map<String, dynamic> json) {
    return VideosResult(
      iso6391: ResultIso6391.fromJson(_str(json['iso_639_1'])),
      iso31661: Iso31661.fromJson(_str(json['iso_3166_1'])),
      name: _str(json['name']),
      key: _str(json['key']),
      site: Site.fromJson(_str(json['site'])),
      size: _int(json['size']),
      type: VideoType.fromJson(_str(json['type'])),
      official: _bool(json['official']),
      id: _str(json['id']),
      publishedAt: _date(json['published_at']),
    );
  }
}

enum Iso31661 {
  US,
  UNKNOWN;

  static Iso31661 fromJson(String value) =>
      value == 'US' ? Iso31661.US : Iso31661.UNKNOWN;
}

enum ResultIso6391 {
  EN,
  UNKNOWN;

  static ResultIso6391 fromJson(String value) =>
      value == 'en' ? ResultIso6391.EN : ResultIso6391.UNKNOWN;
}

enum Site {
  YOU_TUBE,
  UNKNOWN;

  static Site fromJson(String value) =>
      value == 'YouTube' ? Site.YOU_TUBE : Site.UNKNOWN;
}

/// Named `VideoType` (not `Type`) to avoid shadowing `dart:core`'s `Type`.
enum VideoType {
  CLIP,
  TEASER,
  TRAILER,
  UNKNOWN;

  static VideoType fromJson(String value) => switch (value) {
    'Clip' => VideoType.CLIP,
    'Teaser' => VideoType.TEASER,
    'Trailer' => VideoType.TRAILER,
    _ => VideoType.UNKNOWN,
  };
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

class WatchProviderCountry {
  final String link;
  final List<Flatrate>? rent;
  final List<Flatrate>? buy;
  final List<Flatrate>? flatrate;
  final List<Flatrate>? ads;
  final List<Flatrate>? free;

  WatchProviderCountry({
    required this.link,
    this.rent,
    this.buy,
    this.flatrate,
    this.ads,
    this.free,
  });

  factory WatchProviderCountry.fromJson(Map<String, dynamic> json) {
    List<Flatrate>? parseOptional(String key) =>
        json[key] == null ? null : _objList(json[key], Flatrate.fromJson);

    return WatchProviderCountry(
      link: _str(json['link']),
      rent: parseOptional('rent'),
      buy: parseOptional('buy'),
      flatrate: parseOptional('flatrate'),
      ads: parseOptional('ads'),
      free: parseOptional('free'),
    );
  }
}
