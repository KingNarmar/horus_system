import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/company_rpc_constants.dart';
import '../models/company_model.dart';

abstract class CompanyTimezoneRemoteDataSource {
  Future<List<String>> getTimezoneOptions();

  Future<CompanyModel> updateBusinessTimezone({
    required String companyId,
    required String businessTimezone,
  });
}

final class SupabaseCompanyTimezoneRemoteDataSource
    implements CompanyTimezoneRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyTimezoneRemoteDataSource(this._client);

  @override
  Future<List<String>> getTimezoneOptions() async {
    final response = await _client.rpc(CompanyRpcConstants.listTimezones);
    if (response is! List) {
      throw const FormatException('Invalid timezone catalog response.');
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid timezone option response.');
      }
      final value = item['name'];
      if (value is! String) {
        throw const FormatException('Invalid timezone option value.');
      }
      return value;
    }).toList(growable: false);
  }

  @override
  Future<CompanyModel> updateBusinessTimezone({
    required String companyId,
    required String businessTimezone,
  }) async {
    final response = await _client
        .rpc(
          CompanyRpcConstants.updateBusinessTimezone,
          params: {
            CompanyRpcConstants.companyId: companyId,
            CompanyRpcConstants.businessTimezone: businessTimezone,
          },
        )
        .single();

    return CompanyModel.fromMap(Map<String, dynamic>.from(response));
  }
}
