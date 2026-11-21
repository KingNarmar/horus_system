import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/open_invoices_report.dart';
import '../../domain/entities/operational_trip_report.dart';
import '../../domain/entities/report_export_cancellation.dart';
import '../../domain/entities/report_export_progress.dart';
import '../../domain/entities/report_source_page.dart';
import '../../domain/entities/trip_expenses_report.dart';
import '../../domain/entities/trip_net_profit_report.dart';
import '../../domain/failures/report_export_cancelled_failure.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/services/report_source_page_collector.dart';
import '../constants/report_export_snapshot_constants.dart';
import '../datasources/report_export_snapshot_remote_data_source.dart';
import '../mappers/report_source_mappers.dart';
import '../models/open_invoices_report_source_model.dart';
import '../models/operational_report_source_model.dart';
import '../models/report_export_snapshot_model.dart';
import '../models/trip_expenses_report_source_model.dart';
import '../models/trip_net_profit_report_source_model.dart';
import 'reports_repository_failure_mapper.dart';

/// Request-scoped ReportsRepository for export only, not screen loading.
///
/// All linked financial source streams use one frozen server snapshot.
/// Existing Domain report use cases retain ownership of every calculation.
final class PagedReportsRepositoryImpl implements ReportsRepository {
  final ReportExportSnapshotRemoteDataSource _remote;
  final ReportExportCancellation _cancellation;
  final ReportExportProgressCallback? _onProgress;

  const PagedReportsRepositoryImpl({
    required ReportExportSnapshotRemoteDataSource remote,
    required ReportExportCancellation cancellation,
    ReportExportProgressCallback? onProgress,
  }) : _remote = remote,
       _cancellation = cancellation,
       _onProgress = onProgress;

  static const _collector = ReportSourcePageCollector();
  static const _failures = ReportsRepositoryFailureMapper();

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => _withSnapshot<OperationalTripReportSource>(
    companyId: companyId,
    fromDate: fromDate,
    toDate: toDate,
    sourceKind: ReportExportSnapshotConstants.operational,
    permissionCode: ReportsFailureCodes.permissionOperationalView,
    assemble: (snapshot) async {
      final empty = OperationalReportSourceModel.fromMap({
        ...snapshot.sourceHeader,
        'rows': <Object>[],
      }).toEntity();
      final rows = await _collect<OperationalTripReportRow>(
        snapshot: snapshot,
        stream: ReportExportSnapshotConstants.rows,
        completedBefore: 0,
        idOf: (row) => row.tripId,
        parse: (raw) => OperationalReportSourceModel.fromMap({
          ...snapshot.sourceHeader,
          'rows': raw,
        }).toEntity().rows,
      );
      if (rows.failureOrNull != null) return FailureResult(rows.failureOrNull!);
      return Success(
        OperationalTripReportSource(
          metadata: empty.metadata,
          rows: rows.dataOrNull!,
        ),
      );
    },
  );

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => _withSnapshot<TripExpensesReportSource>(
    companyId: companyId,
    fromDate: fromDate,
    toDate: toDate,
    sourceKind: ReportExportSnapshotConstants.tripExpenses,
    permissionCode: ReportsFailureCodes.permissionFinancialView,
    assemble: (snapshot) async {
      final empty = TripExpensesReportSourceModel.fromMap({
        ...snapshot.sourceHeader,
        'rows': <Object>[],
      }).toEntity();
      final rows = await _collect<TripExpenseReportRow>(
        snapshot: snapshot,
        stream: ReportExportSnapshotConstants.rows,
        completedBefore: 0,
        idOf: (row) => row.expenseId,
        parse: (raw) => TripExpensesReportSourceModel.fromMap({
          ...snapshot.sourceHeader,
          'rows': raw,
        }).toEntity().rows,
      );
      if (rows.failureOrNull != null) return FailureResult(rows.failureOrNull!);
      return Success(
        TripExpensesReportSource(
          metadata: empty.metadata,
          precisionLossCount: empty.precisionLossCount,
          negativeAmountCount: empty.negativeAmountCount,
          currencyMismatchCount: empty.currencyMismatchCount,
          rows: rows.dataOrNull!,
        ),
      );
    },
  );

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => _withSnapshot<TripNetProfitReportSource>(
    companyId: companyId,
    fromDate: fromDate,
    toDate: toDate,
    sourceKind: ReportExportSnapshotConstants.tripNetProfit,
    permissionCode: ReportsFailureCodes.permissionFinancialView,
    assemble: (snapshot) async {
      final empty = TripNetProfitReportSourceModel.fromMap({
        ...snapshot.sourceHeader,
        'trips': <Object>[],
        'expenses': <Object>[],
      }).toEntity();
      final trips = await _collect<TripNetProfitSourceTrip>(
        snapshot: snapshot,
        stream: ReportExportSnapshotConstants.trips,
        completedBefore: 0,
        idOf: (row) => row.tripId,
        parse: (raw) => TripNetProfitReportSourceModel.fromMap({
          ...snapshot.sourceHeader,
          'trips': raw,
          'expenses': <Object>[],
        }).toEntity().trips,
      );
      if (trips.failureOrNull != null)
        return FailureResult(trips.failureOrNull!);
      final expenses = await _collect<TripNetProfitSourceExpense>(
        snapshot: snapshot,
        stream: ReportExportSnapshotConstants.expenses,
        completedBefore: trips.dataOrNull!.length,
        idOf: (row) => row.expenseId,
        parse: (raw) => TripNetProfitReportSourceModel.fromMap({
          ...snapshot.sourceHeader,
          'trips': <Object>[],
          'expenses': raw,
        }).toEntity().expenses,
      );
      if (expenses.failureOrNull != null) {
        return FailureResult(expenses.failureOrNull!);
      }
      return Success(
        TripNetProfitReportSource(
          metadata: empty.metadata,
          freightPrecisionLossCount: empty.freightPrecisionLossCount,
          negativeFreightCount: empty.negativeFreightCount,
          expensePrecisionLossCount: empty.expensePrecisionLossCount,
          negativeExpenseCount: empty.negativeExpenseCount,
          expenseCurrencyMismatchCount: empty.expenseCurrencyMismatchCount,
          trips: trips.dataOrNull!,
          expenses: expenses.dataOrNull!,
        ),
      );
    },
  );

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => _withSnapshot<OpenInvoicesReportSource>(
    companyId: companyId,
    fromDate: fromDate,
    toDate: toDate,
    sourceKind: ReportExportSnapshotConstants.openInvoices,
    permissionCode: ReportsFailureCodes.permissionOpenInvoicesView,
    assemble: (snapshot) async {
      final empty = OpenInvoicesReportSourceModel.fromMap({
        ...snapshot.sourceHeader,
        'invoices': <Object>[],
        'payments': <Object>[],
      }).toEntity();
      final invoices = await _collect<OpenInvoiceSourceInvoice>(
        snapshot: snapshot,
        stream: ReportExportSnapshotConstants.invoices,
        completedBefore: 0,
        idOf: (row) => row.invoiceId,
        parse: (raw) => OpenInvoicesReportSourceModel.fromMap({
          ...snapshot.sourceHeader,
          'invoices': raw,
          'payments': <Object>[],
        }).toEntity().invoices,
      );
      if (invoices.failureOrNull != null) {
        return FailureResult(invoices.failureOrNull!);
      }
      final payments = await _collect<OpenInvoiceSourcePayment>(
        snapshot: snapshot,
        stream: ReportExportSnapshotConstants.payments,
        completedBefore: invoices.dataOrNull!.length,
        idOf: (row) => row.paymentId,
        parse: (raw) => OpenInvoicesReportSourceModel.fromMap({
          ...snapshot.sourceHeader,
          'invoices': <Object>[],
          'payments': raw,
        }).toEntity().payments,
      );
      if (payments.failureOrNull != null) {
        return FailureResult(payments.failureOrNull!);
      }
      return Success(
        OpenInvoicesReportSource(
          metadata: empty.metadata,
          invoiceCurrencyMismatchCount: empty.invoiceCurrencyMismatchCount,
          paymentCurrencyMismatchCount: empty.paymentCurrencyMismatchCount,
          invalidInvoiceAmountCount: empty.invalidInvoiceAmountCount,
          invalidPaymentAmountCount: empty.invalidPaymentAmountCount,
          missingIssueDateCount: empty.missingIssueDateCount,
          invoices: invoices.dataOrNull!,
          payments: payments.dataOrNull!,
        ),
      );
    },
  );

  Future<Result<List<T>>> _collect<T>({
    required ReportExportSnapshotModel snapshot,
    required String stream,
    required int completedBefore,
    required String Function(T) idOf,
    required List<T> Function(List<Map<String, dynamic>>) parse,
  }) {
    final count = snapshot.countFor(stream);
    final total = snapshot.streamCounts.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return _collector.collect<T>(
      cancellation: _cancellation,
      idOf: idOf,
      readPage: (cursor) async {
        final page = await _remote.read(
          snapshotId: snapshot.snapshotId,
          stream: stream,
          cursor: cursor,
          pageSize: ReportExportSnapshotConstants.pageSize,
        );
        if (page.snapshotToken != snapshot.snapshotId ||
            page.stream != stream ||
            page.totalRows != count ||
            page.rows.length > ReportExportSnapshotConstants.pageSize) {
          throw const FormatException('Invalid frozen snapshot page.');
        }
        return Success(
          ReportSourcePage<T>(
            snapshotToken: page.snapshotToken,
            totalRows: page.totalRows,
            rows: parse(page.rows),
            nextCursor: page.nextCursor,
          ),
        );
      },
      onProgress: (page) => _onProgress?.call(
        ReportExportProgress(
          stage: ReportExportStage.readingSource,
          loadedRows: completedBefore + page.loadedRows!,
          totalRows: total,
        ),
      ),
    );
  }

  Future<Result<T>> _withSnapshot<T>({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
    required String sourceKind,
    required String permissionCode,
    required Future<Result<T>> Function(ReportExportSnapshotModel) assemble,
  }) async {
    if (_cancellation.isCancelled) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    ReportExportSnapshotModel? snapshot;
    Result<T> result;
    try {
      snapshot = await _remote.start(
        companyId: companyId,
        sourceKind: sourceKind,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (snapshot.companyId != companyId ||
          snapshot.sourceKind != sourceKind) {
        throw const FormatException('Report export snapshot scope mismatch.');
      }
      result = _cancellation.isCancelled
          ? const FailureResult(ReportExportCancelledFailure())
          : await assemble(snapshot);
    } on AuthException catch (error) {
      result = FailureResult(_failures.fromAuthException(error));
    } on PostgrestException catch (error) {
      result = FailureResult(
        _failures.fromPostgrest(error, permissionFailureCode: permissionCode),
      );
    } on FormatException {
      result = const FailureResult(
        ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
      );
    } catch (error) {
      result = FailureResult(_failures.fromUnexpected(error));
    }

    // Release is required even for failed/cancelled requests. Return a typed
    // failure if cleanup fails after success; server expiry is the backstop.
    if (snapshot != null) {
      try {
        final released = await _remote.release(snapshot.snapshotId);
        if (!released && result.isSuccess) {
          return const FailureResult(
            ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
          );
        }
      } on AuthException catch (error) {
        if (result.isSuccess) {
          return FailureResult(_failures.fromAuthException(error));
        }
      } on PostgrestException catch (error) {
        if (result.isSuccess) {
          return FailureResult(
            _failures.fromPostgrest(
              error,
              permissionFailureCode: permissionCode,
            ),
          );
        }
      } catch (error) {
        if (result.isSuccess) {
          return FailureResult(_failures.fromUnexpected(error));
        }
      }
    }
    if (_cancellation.isCancelled) {
      return const FailureResult(ReportExportCancelledFailure());
    }
    return result;
  }
}
