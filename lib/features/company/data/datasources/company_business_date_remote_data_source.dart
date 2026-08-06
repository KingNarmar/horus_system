import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_rpc_constants.dart';
import '../models/company_business_date_model.dart';

abstract interface class CompanyBusinessDateRemoteDataSource {
  Future<CompanyBusinessDateModel> getBusinessDate({required String companyId});
}

final class SupabaseCompanyBusinessDateRemoteDataSource
    implements CompanyBusinessDateRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyBusinessDateRemoteDataSource(this._client);

  @override
  Future<CompanyBusinessDateModel> getBusinessDate({
    required String companyId,
  }) async {
    final response = await _client.rpc(
      CompanyRpcConstants.getBusinessDate,
      params: {CompanyRpcConstants.companyId: companyId},
    );
    return CompanyBusinessDateModel.fromValue(response);
  }
}
