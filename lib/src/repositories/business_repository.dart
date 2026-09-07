import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'repository_helpers.dart';

class BusinessProfileAlreadyExistsException implements Exception {
  const BusinessProfileAlreadyExistsException();

  @override
  String toString() => 'Your account already has a business profile.';
}

class BusinessRepository {
  BusinessRepository(this._client);

  final SupabaseClient _client;

  Future<Business?> fetchForUser(String userId) async {
    final rows = await _client
        .selectRows('businesses')
        .eq('owner_id', userId)
        .order('created_at')
        .limit(1);

    return rows.isEmpty ? null : Business.fromJson(rows.first);
  }

  Future<Business> create({
    required String ownerId,
    required String name,
  }) async {
    final existingBusiness = await fetchForUser(ownerId);
    if (existingBusiness != null) return existingBusiness;

    try {
      return await mapSingleRow(
        _client
            .from('businesses')
            .insert({'owner_id': ownerId, 'name': name.trim()})
            .select()
            .single(),
        Business.fromJson,
      );
    } on PostgrestException catch (error) {
      if (_isDuplicateBusinessProfileError(error)) {
        final existingBusiness = await fetchForUser(ownerId);
        if (existingBusiness != null) return existingBusiness;
        throw const BusinessProfileAlreadyExistsException();
      }
      rethrow;
    }
  }

  Future<Business> updateName({
    required String businessId,
    required String name,
  }) async {
    return mapSingleRow(
      _client
          .from('businesses')
          .update({'name': name.trim()})
          .eq('id', businessId)
          .select()
          .single(),
      Business.fromJson,
    );
  }

  bool _isDuplicateBusinessProfileError(PostgrestException error) {
    final details = error.details?.toString() ?? '';
    final hint = error.hint?.toString() ?? '';
    final combined = '${error.message} $details $hint'.toLowerCase();
    return error.code == '23505' ||
        combined.contains('one business profile') ||
        combined.contains('businesses_one_profile_per_owner');
  }
}
