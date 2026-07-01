String _str(dynamic v) => v is String ? v : '';
String? _strOrNull(dynamic v) => v is String ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
double _double(dynamic v) => v is num ? v.toDouble() : 0;
List<T> _objList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is! List) return <T>[];
  return v.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

class PersonDetail {
  final int id;
  final String name;
  final String? profilePath;
  final String biography;
  final String birthday;
  final String? deathday;
  final String placeOfBirth;
  final String knownForDepartment;
  final double popularity;
  final PersonCredits? combinedCredits;

  PersonDetail({
    required this.id,
    required this.name,
    this.profilePath,
    required this.biography,
    required this.birthday,
    this.deathday,
    required this.placeOfBirth,
    required this.knownForDepartment,
    required this.popularity,
    this.combinedCredits,
  });

  factory PersonDetail.fromJson(Map<String, dynamic> json) {
    return PersonDetail(
      id: _int(json['id']),
      name: _str(json['name']),
      profilePath: _strOrNull(json['profile_path']),
      biography: _str(json['biography']),
      birthday: _str(json['birthday']),
      deathday: _strOrNull(json['deathday']),
      placeOfBirth: _str(json['place_of_birth']),
      knownForDepartment: _str(json['known_for_department']),
      popularity: _double(json['popularity']),
      combinedCredits: json['combined_credits'] is Map<String, dynamic>
          ? PersonCredits.fromJson(
              json['combined_credits'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PersonCredits {
  final List<PersonCredit> cast;

  PersonCredits({required this.cast});

  factory PersonCredits.fromJson(Map<String, dynamic> json) {
    return PersonCredits(
      cast: _objList(json['cast'], PersonCredit.fromJson),
    );
  }
}

class PersonCredit {
  final int id;
  final String title;
  final String? posterPath;
  final String mediaType;
  final double voteAverage;
  final String? character;
  final String releaseDate;
  final double popularity;

  PersonCredit({
    required this.id,
    required this.title,
    this.posterPath,
    required this.mediaType,
    required this.voteAverage,
    this.character,
    required this.releaseDate,
    required this.popularity,
  });

  factory PersonCredit.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] ?? json['name'];
    final rawDate = json['release_date'] ?? json['first_air_date'];
    return PersonCredit(
      id: _int(json['id']),
      title: rawTitle is String ? rawTitle : '',
      posterPath: _strOrNull(json['poster_path']),
      mediaType: _str(json['media_type']),
      voteAverage: _double(json['vote_average']),
      character: _strOrNull(json['character']),
      releaseDate: rawDate is String ? rawDate : '',
      popularity: _double(json['popularity']),
    );
  }
}
