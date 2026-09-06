import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'repository_helpers.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final SupabaseClient _client;

  Future<Business?> fetchForUser(String userId) async {
    final ownedRows = await _client
        .selectRows('businesses')
        .eq('owner_id', userId)
        .order('created_at')
        .limit(1);

    if (ownedRows.isNotEmpty) {
      return Business.fromJson(ownedRows.first);
    }

    final memberRows = await _client
        .selectRows('business_members', columns: 'businesses(*)')
        .eq('user_id', userId)
        .limit(1);

    if (memberRows.isEmpty) return null;
    final business = readMap(readMap(memberRows.first)['businesses']);
    return business.isEmpty ? null : Business.fromJson(business);
  }

  Future<Business> create({
    required String ownerId,
    required String name,
  }) async {
    return mapSingleRow(
      _client
          .from('businesses')
          .insert({'owner_id': ownerId, 'name': name.trim()})
          .select()
          .single(),
      Business.fromJson,
    );
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
}
