import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_users_rpc.dart';
import '../models/company_user_model.dart';

abstract class CompanyUsersRemoteDataSource {
  Future<List<CompanyUserModel>> getCompanyUsers({required String companyId});
}

class SupabaseCompanyUsersRemoteDataSource
    implements CompanyUsersRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyUsersRemoteDataSource(this._client);

  @override
  Future<List<CompanyUserModel>> getCompanyUsers({
    required String companyId,
  }) async {
    final response = await _client.rpc(
      CompanyUsersRpc.list,
      params: {CompanyUsersRpc.companyIdParam: companyId},
    );

    if (response is! List) {
      throw const FormatException('Invalid company users RPC response.');
    }

    return response
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Invalid company user RPC row.');
          }
          return CompanyUserModel.fromRpcMap(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }
}
