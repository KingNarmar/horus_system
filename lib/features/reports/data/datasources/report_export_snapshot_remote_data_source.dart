import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../constants/reports_db_constants.dart';
import '../models/report_export_snapshot_model.dart';

abstract interface class ReportExportSnapshotRemoteDataSource {
  Future<ReportExportSnapshotModel> start({
    required String companyId,
    required String sourceKind,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  });

  Future<ReportExportSnapshotPageModel> read({
    required String snapshotId,
    required String stream,
    required String? cursor,
    required int pageSize,
  });

  Future<bool> release(String snapshotId);
}

/// Only Data talks to Supabase; snapshots remain private DB resources.
final class SupabaseReportExportSnapshotRemoteDataSource
    implements ReportExportSnapshotRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseReportExportSnapshotRemoteDataSource(this._client);

  @override
  Future<ReportExportSnapshotModel> start({
    required String companyId,
    required String sourceKind,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    final response = await _client.rpc(
      ReportsDbConstants.startSnapshotRpc,
      params: {
        ReportsDbConstants.companyIdParam: companyId,
        ReportsDbConstants.sourceKindParam: sourceKind,
        ReportsDbConstants.fromDateParam: DbDate.encodeNullable(fromDate),
        ReportsDbConstants.toDateParam: DbDate.encodeNullable(toDate),
      },
    );
    return ReportExportSnapshotModel.fromMap(_singleObject(response));
  }

  @override
  Future<ReportExportSnapshotPageModel> read({
    required String snapshotId,
    required String stream,
    required String? cursor,
    required int pageSize,
  }) async {
    final response = await _client.rpc(
      ReportsDbConstants.readSnapshotPageRpc,
      params: {
        ReportsDbConstants.snapshotIdParam: snapshotId,
        ReportsDbConstants.streamParam: stream,
        ReportsDbConstants.cursorParam: cursor,
        ReportsDbConstants.pageSizeParam: pageSize,
      },
    );
    return ReportExportSnapshotPageModel.fromMap(_singleObject(response));
  }

  @override
  Future<bool> release(String snapshotId) async {
    final response = await _client.rpc(
      ReportsDbConstants.releaseSnapshotRpc,
      params: {ReportsDbConstants.snapshotIdParam: snapshotId},
    );
    if (response is! bool) {
      throw const FormatException('Invalid export snapshot release.');
    }
    return response;
  }
}

Map<String, dynamic> _singleObject(Object? response) {
  if (response is Map) return Map<String, dynamic>.from(response);
  if (response is List && response.length == 1 && response.single is Map) {
    return Map<String, dynamic>.from(response.single as Map);
  }
  throw const FormatException('Invalid report snapshot RPC response.');
}
