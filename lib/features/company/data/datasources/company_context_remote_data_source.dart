import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_membership_model.dart';

abstract class CompanyContextRemoteDataSource {
  Future<List<CompanyMembershipModel>> loadUserCompanyMemberships();
}

class SupabaseCompanyContextRemoteDataSource
    implements CompanyContextRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyContextRemoteDataSource(this._client);

  @override
  Future<List<CompanyMembershipModel>> loadUserCompanyMemberships() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw AuthException(
        'User must be authenticated to load company context.',
      );
    }

    final response = await _client
        .from('company_users')
        .select(
          'role,is_active,companies!inner(id,name,business_type,phone,email,country,city,logo_url,is_active)',
        )
        .eq('user_id', userId)
        .eq('is_active', true)
        .eq('companies.is_active', true)
        .order('created_at');

    return response
        .map(
          (item) =>
              CompanyMembershipModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
