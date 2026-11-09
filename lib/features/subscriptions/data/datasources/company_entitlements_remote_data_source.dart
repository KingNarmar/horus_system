import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_entitlement_rpc.dart';

abstract interface class CompanyEntitlementsRemoteDataSource {
  Future<Map<String, dynamic>?> getCurrent({required String companyId});
}

final class SupabaseCompanyEntitlementsRemoteDataSource
    implements CompanyEntitlementsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyEntitlementsRemoteDataSource(this._client);

  @override
  Future<Map<String, dynamic>?> getCurrent({required String companyId}) async {
    final response = await _client.rpc(
      CompanyEntitlementRpc.getCurrent,
      params: {CompanyEntitlementRpc.companyId: companyId},
    );
    if (response == null) return null;
    if (response is! Map) {
      throw const FormatException('Invalid entitlement projection');
    }
    return Map<String, dynamic>.from(response);
  }
}
