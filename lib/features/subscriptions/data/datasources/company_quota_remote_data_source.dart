import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_quota_rpc.dart';

abstract interface class CompanyQuotaRemoteDataSource {
  Future<Map<String, dynamic>?> getUsage({required String companyId});
}

final class SupabaseCompanyQuotaRemoteDataSource
    implements CompanyQuotaRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyQuotaRemoteDataSource(this._client);

  @override
  Future<Map<String, dynamic>?> getUsage({required String companyId}) async {
    final response = await _client.rpc(
      CompanyQuotaRpc.getUsage,
      params: {CompanyQuotaRpc.companyId: companyId},
    );
    if (response == null) return null;
    if (response is! Map) {
      throw const FormatException('Invalid quota response');
    }
    return Map<String, dynamic>.from(response);
  }
}
