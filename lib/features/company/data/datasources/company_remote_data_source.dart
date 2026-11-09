import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_db_fields.dart';
import '../constants/company_rpc_constants.dart';
import '../models/company_model.dart';
import '../services/company_creation_request_identity.dart';

abstract class CompanyRemoteDataSource {
  Future<CompanyModel> createCompany({
    required String name,
    required String businessTimezone,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String invoicePrefix,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  });

  Future<List<CompanyModel>> getMyCompanies();
}

class SupabaseCompanyRemoteDataSource implements CompanyRemoteDataSource {
  final SupabaseClient _client;
  final CompanyCreationRequestIdentity _requestIdentity;

  SupabaseCompanyRemoteDataSource(
    this._client, {
    CompanyCreationRequestIdentity? requestIdentity,
  }) : _requestIdentity = requestIdentity ?? CompanyCreationRequestIdentity();

  @override
  Future<CompanyModel> createCompany({
    required String name,
    required String businessTimezone,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String invoicePrefix,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    final parameters = <String, Object?>{
      CompanyRpcConstants.companyName: name,
      CompanyRpcConstants.businessTimezone: businessTimezone,
      CompanyRpcConstants.baseCurrencyCode: baseCurrencyCode,
      CompanyRpcConstants.baseCurrencyFractionDigits:
          baseCurrencyFractionDigits,
      CompanyRpcConstants.invoicePrefix: invoicePrefix,
      CompanyRpcConstants.businessType: businessType,
      CompanyRpcConstants.phone: phone,
      CompanyRpcConstants.email: email,
      CompanyRpcConstants.country: country,
      CompanyRpcConstants.city: city,
    };
    final requestId = _requestIdentity.getOrCreate(parameters);
    final response = await _client
        .rpc(
          CompanyRpcConstants.createCompany,
          params: {
            ...parameters,
            CompanyRpcConstants.requestId: requestId,
          },
        )
        .single();

    final company = CompanyModel.fromMap(Map<String, dynamic>.from(response));
    _requestIdentity.complete(requestId);
    return company;
  }

  @override
  Future<List<CompanyModel>> getMyCompanies() async {
    final response = await _client
        .from(CompanyDbFields.companiesTable)
        .select(_companySelectColumns)
        .eq(DbCommonFields.isActive, true)
        .order(DbCommonFields.createdAt);

    return response
        .map((item) => CompanyModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}

final _companySelectColumns = <String>[
  DbCommonFields.id,
  CompanyDbFields.name,
  CompanyDbFields.businessType,
  CompanyDbFields.phone,
  CompanyDbFields.email,
  CompanyDbFields.country,
  CompanyDbFields.city,
  CompanyDbFields.logoUrl,
  CompanyDbFields.baseCurrencyCode,
  CompanyDbFields.baseCurrencyFractionDigits,
  CompanyDbFields.businessTimezone,
  DbCommonFields.isActive,
].join(',');
