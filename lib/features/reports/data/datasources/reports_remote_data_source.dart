import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/reports_db_constants.dart';
import '../models/open_invoices_report_source_model.dart';
import '../models/operational_report_source_model.dart';
import '../models/trip_expenses_report_source_model.dart';
import '../models/trip_net_profit_report_source_model.dart';

abstract interface class ReportsRemoteDataSource {
  Future<OperationalReportSourceModel> getOperationalSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });

  Future<TripExpensesReportSourceModel> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });

  Future<TripNetProfitReportSourceModel> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });

  Future<OpenInvoicesReportSourceModel> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  });
}

final class SupabaseReportsRemoteDataSource implements ReportsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseReportsRemoteDataSource(this._client);

  @override
  Future<OperationalReportSourceModel> getOperationalSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final response = await _rpc(
      ReportsDbConstants.operationalRpc,
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
    );
    return OperationalReportSourceModel.fromMap(response);
  }

  @override
  Future<TripExpensesReportSourceModel> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final response = await _rpc(
      ReportsDbConstants.tripExpensesRpc,
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
    );
    return TripExpensesReportSourceModel.fromMap(response);
  }

  @override
  Future<TripNetProfitReportSourceModel> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final response = await _rpc(
      ReportsDbConstants.tripNetProfitRpc,
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
    );
    return TripNetProfitReportSourceModel.fromMap(response);
  }

  @override
  Future<OpenInvoicesReportSourceModel> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final response = await _rpc(
      ReportsDbConstants.openInvoicesRpc,
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
    );
    return OpenInvoicesReportSourceModel.fromMap(response);
  }

  Future<Map<String, dynamic>> _rpc(
    String functionName, {
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    final response = await _client.rpc(
      functionName,
      params: {
        ReportsDbConstants.companyIdParam: companyId,
        ReportsDbConstants.fromDateParam: _dateParam(fromDate),
        ReportsDbConstants.toDateParam: _dateParam(toDate),
      },
    );
    return _singleMap(response);
  }
}

String? _dateParam(DateTime? date) {
  if (date == null) return null;
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

Map<String, dynamic> _singleMap(Object? response) {
  if (response is Map) return Map<String, dynamic>.from(response);
  if (response is List && response.length == 1 && response.single is Map) {
    return Map<String, dynamic>.from(response.single as Map);
  }
  throw const FormatException('Invalid reports RPC response.');
}
