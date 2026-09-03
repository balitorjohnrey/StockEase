import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class BusinessRepository {
  BusinessRepository(this._client);

  final SupabaseClient _client;

  Future<Business?> fetchForUser(String userId) async {
    final ownedRows = await _client
        .from('businesses')
        .select()
        .eq('owner_id', userId)
        .order('created_at')
        .limit(1) as List<dynamic>;

    if (ownedRows.isNotEmpty) {
      return Business.fromJson(readMap(ownedRows.first));
    }

    final memberRows = await _client
        .from('business_members')
        .select('businesses(*)')
        .eq('user_id', userId)
        .limit(1) as List<dynamic>;

    if (memberRows.isEmpty) return null;
    final business = readMap(readMap(memberRows.first)['businesses']);
    return business.isEmpty ? null : Business.fromJson(business);
  }

  Future<Business> create({
    required String ownerId,
    required String name,
  }) async {
    final response = await _client
        .from('businesses')
        .insert({'owner_id': ownerId, 'name': name.trim()})
        .select()
        .single();
    return Business.fromJson(readMap(response));
  }

  Future<Business> updateName({
    required String businessId,
    required String name,
  }) async {
    final response = await _client
        .from('businesses')
        .update({'name': name.trim()})
        .eq('id', businessId)
        .select()
        .single();
    return Business.fromJson(readMap(response));
  }
}
