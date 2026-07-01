import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/network/tmdb_dio_provider.dart';
import '../models/person_detail.dart';

class PersonService {
  const PersonService(this._tmdbDio);

  final Dio _tmdbDio;

  Future<PersonDetail> fetchDetail(int personId) async {
    final response = await _tmdbDio.get(
      '/person/$personId',
      queryParameters: {
        'api_key': AppConfig.tmdbApiKey,
        'append_to_response': 'combined_credits',
      },
    );
    return PersonDetail.fromJson(response.data as Map<String, dynamic>);
  }
}

final personServiceProvider = Provider<PersonService>(
  (ref) => PersonService(ref.watch(tmdbDioProvider)),
);
