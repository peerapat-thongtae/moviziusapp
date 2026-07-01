import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person_detail.dart';
import '../services/person_service.dart';

final personDetailProvider = FutureProvider.family<PersonDetail, int>(
  (ref, personId) => ref.watch(personServiceProvider).fetchDetail(personId),
);
