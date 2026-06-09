import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_user_model.dart';

abstract class CompanyUsersRemoteDataSource {
  Future<List<CompanyUserModel>> getCompanyUsers({
    required String companyId,
  });
}

class SupabaseCompanyUsersRemoteDataSource
    implements CompanyUsersRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyUsersRemoteDataSource(this._client);

  @override
  Future<List<CompanyUserModel>> getCompanyUsers({
    required String companyId,
  }) async {
    final response = await _client
        .from('company_users')
        .select('id,company_id,user_id,role,is_active')
        .eq('company_id', companyId)
        .order('created_at');

    return response
        .map(
          (item) => CompanyUserModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
