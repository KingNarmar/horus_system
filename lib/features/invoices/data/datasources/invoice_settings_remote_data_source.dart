import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/value_objects/invoice_prefix.dart';
import '../constants/invoices_db_fields.dart';
import '../constants/invoices_rpc_constants.dart';
import '../models/company_invoice_settings_model.dart';

abstract interface class InvoiceSettingsRemoteDataSource {
  Future<CompanyInvoiceSettingsModel?> get({required String companyId});

  Future<CompanyInvoiceSettingsModel> update({
    required String companyId,
    required InvoicePrefix prefix,
  });
}

final class SupabaseInvoiceSettingsRemoteDataSource
    implements InvoiceSettingsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseInvoiceSettingsRemoteDataSource(this._client);

  @override
  Future<CompanyInvoiceSettingsModel?> get({required String companyId}) async {
    final response = await _client
        .from(InvoicesDbFields.companyInvoiceSettingsTable)
        .select(_settingsSelectColumns)
        .eq(DbCommonFields.companyId, companyId)
        .maybeSingle();

    if (response == null) return null;
    return CompanyInvoiceSettingsModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<CompanyInvoiceSettingsModel> update({
    required String companyId,
    required InvoicePrefix prefix,
  }) async {
    final response = await _client
        .rpc(
          InvoicesRpcConstants.updateSettings,
          params: {
            InvoicesRpcConstants.companyId: companyId,
            InvoicesRpcConstants.invoicePrefix: prefix.value,
          },
        )
        .single();

    return CompanyInvoiceSettingsModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}

final _settingsSelectColumns = <String>[
  DbCommonFields.companyId,
  InvoicesDbFields.invoicePrefix,
].join(',');
