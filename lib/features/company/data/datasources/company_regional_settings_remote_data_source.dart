import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_rpc_constants.dart';
import '../models/company_model.dart';

abstract interface class CompanyRegionalSettingsRemoteDataSource {
  Future<CompanyModel> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String businessTimezone,
  });
}

final class SupabaseCompanyRegionalSettingsRemoteDataSource
    implements CompanyRegionalSettingsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyRegionalSettingsRemoteDataSource(this._client);

  @override
  Future<CompanyModel> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String businessTimezone,
  }) async {
    final response = await _client
        .rpc(
          CompanyRpcConstants.updateRegionalSettings,
          params: {
            CompanyRpcConstants.companyId: companyId,
            CompanyRpcConstants.baseCurrencyCode: baseCurrencyCode,
            CompanyRpcConstants.baseCurrencyFractionDigits:
                baseCurrencyFractionDigits,
            CompanyRpcConstants.businessTimezone: businessTimezone,
          },
        )
        .single();

    return CompanyModel.fromMap(Map<String, dynamic>.from(response));
  }
}
