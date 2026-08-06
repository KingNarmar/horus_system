import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/value_objects/invoice_date.dart';
import '../constants/invoices_db_fields.dart';
import '../constants/invoices_db_selects.dart';
import '../constants/invoices_rpc_constants.dart';
import '../models/billable_trip_model.dart';
import '../models/invoice_creation_context_model.dart';
import '../models/invoice_draft_write_model.dart';
import '../models/invoice_model.dart';
import '../utils/invoice_data_parser.dart';

abstract interface class InvoicesRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices({required String companyId});

  Future<InvoiceModel> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  });

  Future<List<BillableTripModel>> getBillableTrips({
    required String companyId,
    String? customerId,
  });

  Future<InvoiceCreationContextModel> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  });

  Future<InvoiceModel> createDraft({required InvoiceDraftWriteModel data});

  Future<InvoiceModel> updateDraft({
    required String invoiceId,
    required InvoiceDraftWriteModel data,
  });

  Future<InvoiceModel> issue({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
  });

  Future<InvoiceModel> cancel({
    required String companyId,
    required String invoiceId,
    required String reason,
  });
}

final class SupabaseInvoicesRemoteDataSource
    implements InvoicesRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseInvoicesRemoteDataSource(this._client);

  @override
  Future<List<InvoiceModel>> getInvoices({required String companyId}) async {
    final response = await _client
        .from(InvoicesDbFields.invoicesTable)
        .select(InvoicesDbSelects.aggregate)
        .eq(DbCommonFields.companyId, companyId)
        .order(DbCommonFields.createdAt, ascending: false);

    return response
        .map((item) => InvoiceModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<InvoiceModel> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    final response = await _client
        .from(InvoicesDbFields.invoicesTable)
        .select(InvoicesDbSelects.aggregate)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.id, invoiceId)
        .single();

    return InvoiceModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<List<BillableTripModel>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) async {
    final response = await _client.rpc(
      InvoicesRpcConstants.getBillableTrips,
      params: {
        InvoicesRpcConstants.companyId: companyId,
        InvoicesRpcConstants.customerId: customerId,
      },
    );
    final maps = InvoiceDataParser.mapList(
      response,
      InvoicesRpcConstants.getBillableTrips,
    );
    return maps.map(BillableTripModel.fromMap).toList(growable: false);
  }

  @override
  Future<InvoiceCreationContextModel> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) async {
    final response = await _client.rpc(
      InvoicesRpcConstants.getCreationContext,
      params: {
        InvoicesRpcConstants.companyId: companyId,
        InvoicesRpcConstants.tripIds: tripIds,
      },
    );
    if (response is! Map) {
      throw const FormatException('Invalid invoice creation context.');
    }
    return InvoiceCreationContextModel.fromMap(
      Map<String, dynamic>.from(response),
      companyId: companyId,
    );
  }

  @override
  Future<InvoiceModel> createDraft({
    required InvoiceDraftWriteModel data,
  }) async {
    final response = await _client.rpc(
      InvoicesRpcConstants.createDraft,
      params: data.createParams(),
    );
    final invoiceId = InvoiceDataParser.requiredString(
      response,
      InvoicesRpcConstants.createDraft,
    );
    return getInvoiceDetails(companyId: data.companyId, invoiceId: invoiceId);
  }

  @override
  Future<InvoiceModel> updateDraft({
    required String invoiceId,
    required InvoiceDraftWriteModel data,
  }) async {
    final response = await _client.rpc(
      InvoicesRpcConstants.updateDraft,
      params: data.updateParams(invoiceId: invoiceId),
    );
    final updatedInvoiceId = InvoiceDataParser.requiredString(
      response,
      InvoicesRpcConstants.updateDraft,
    );
    return getInvoiceDetails(
      companyId: data.companyId,
      invoiceId: updatedInvoiceId,
    );
  }

  @override
  Future<InvoiceModel> issue({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
  }) async {
    final response = await _client.rpc(
      InvoicesRpcConstants.issue,
      params: {
        InvoicesRpcConstants.companyId: companyId,
        InvoicesRpcConstants.invoiceId: invoiceId,
        InvoicesRpcConstants.issueDate: _dateValue(issueDate),
        InvoicesRpcConstants.dueDate: _dateValue(dueDate),
      },
    );
    final issuedInvoiceId = InvoiceDataParser.requiredString(
      response,
      InvoicesRpcConstants.issue,
    );
    return getInvoiceDetails(companyId: companyId, invoiceId: issuedInvoiceId);
  }

  @override
  Future<InvoiceModel> cancel({
    required String companyId,
    required String invoiceId,
    required String reason,
  }) async {
    final response = await _client.rpc(
      InvoicesRpcConstants.cancel,
      params: {
        InvoicesRpcConstants.companyId: companyId,
        InvoicesRpcConstants.invoiceId: invoiceId,
        InvoicesRpcConstants.reason: reason,
      },
    );
    final cancelledInvoiceId = InvoiceDataParser.requiredString(
      response,
      InvoicesRpcConstants.cancel,
    );
    return getInvoiceDetails(
      companyId: companyId,
      invoiceId: cancelledInvoiceId,
    );
  }
}

String _dateValue(InvoiceDate date) {
  return date.value.toIso8601String().substring(0, 10);
}
