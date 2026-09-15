import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_rpc_constants.dart';
import '../models/company_model.dart';

abstract class CompanyFinancialSettingsRemoteDataSource {
  Future<CompanyModel> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  });
}

final class SupabaseCompanyFinancialSettingsRemoteDataSource
    implements CompanyFinancialSettingsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyFinancialSettingsRemoteDataSource(this._client);

  @override
  Future<CompanyModel> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  }) async {
    final response = await _client
        .rpc(
          CompanyRpcConstants.updateFinancialConfiguration,
          params: {
            CompanyRpcConstants.companyId: companyId,
            CompanyRpcConstants.baseCurrencyCode: baseCurrencyCode,
            CompanyRpcConstants.baseCurrencyFractionDigits:
                baseCurrencyFractionDigits,
          },
        )
        .single();

    return CompanyModel.fromMap(Map<String, dynamic>.from(response));
  }
}
