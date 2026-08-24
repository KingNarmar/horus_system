import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/reports/data/constants/reports_db_constants.dart';
import 'package:horus_system/features/reports/data/datasources/reports_remote_data_source.dart';
import 'package:horus_system/features/reports/data/models/open_invoices_report_source_model.dart';
import 'package:horus_system/features/reports/data/models/operational_report_source_model.dart';
import 'package:horus_system/features/reports/data/models/report_source_metadata_model.dart';
import 'package:horus_system/features/reports/data/models/trip_expenses_report_source_model.dart';
import 'package:horus_system/features/reports/data/models/trip_net_profit_report_source_model.dart';
import 'package:horus_system/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ReportsRepositoryImpl', () {
    test('preserves company/date scope and maps all report sources', () async {
      final dataSource = _FakeReportsRemoteDataSource();
      final repository = ReportsRepositoryImpl(dataSource);
      final fromDate = DateTime(2026, 8, 1);
      final toDate = DateTime(2026, 8, 31);

      final operational = await repository.getOperationalTripSource(
        companyId: 'company-1',
        fromDate: fromDate,
        toDate: toDate,
      );
      final expenses = await repository.getTripExpensesSource(
        companyId: 'company-1',
        fromDate: fromDate,
        toDate: toDate,
      );
      final netProfit = await repository.getTripNetProfitSource(
        companyId: 'company-1',
        fromDate: fromDate,
        toDate: toDate,
      );
      final openInvoices = await repository.getOpenInvoicesSource(
        companyId: 'company-1',
        fromDate: fromDate,
        toDate: toDate,
      );

      expect(operational.isSuccess, isTrue);
      expect(expenses.isSuccess, isTrue);
      expect(netProfit.isSuccess, isTrue);
      expect(openInvoices.isSuccess, isTrue);
      expect(operational.dataOrNull?.metadata.companyId, 'company-1');
      expect(expenses.dataOrNull?.metadata.companyId, 'company-1');
      expect(netProfit.dataOrNull?.metadata.companyId, 'company-1');
      expect(openInvoices.dataOrNull?.metadata.companyId, 'company-1');
      expect(dataSource.calls, hasLength(4));
      expect(
        dataSource.calls.map((call) => call.operation).toList(growable: false),
        const [
          _ReportOperation.operational,
          _ReportOperation.tripExpenses,
          _ReportOperation.tripNetProfit,
          _ReportOperation.openInvoices,
        ],
      );
      for (final call in dataSource.calls) {
        expect(call.companyId, 'company-1');
        expect(call.fromDate, fromDate);
        expect(call.toDate, toDate);
      }
    });

    test('uses operational permission code for operational reports', () async {
      final repository = ReportsRepositoryImpl(
        _FakeReportsRemoteDataSource(
          error: const PostgrestException(
            message: 'permission denied',
            code: ReportsRpcErrorCodes.permissionDenied,
          ),
        ),
      );

      final result = await repository.getOperationalTripSource(
        companyId: 'company-1',
        fromDate: null,
        toDate: null,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        ReportsFailureCodes.permissionOperationalView,
      );
    });

    test('uses financial permission code for financial reports', () async {
      final repository = ReportsRepositoryImpl(
        _FakeReportsRemoteDataSource(
          error: const PostgrestException(
            message: 'permission denied',
            code: ReportsRpcErrorCodes.permissionDenied,
          ),
        ),
      );

      final result = await repository.getTripExpensesSource(
        companyId: 'company-1',
        fromDate: null,
        toDate: null,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        ReportsFailureCodes.permissionFinancialView,
      );
    });

    test('uses open-invoices permission code for invoice reports', () async {
      final repository = ReportsRepositoryImpl(
        _FakeReportsRemoteDataSource(
          error: const PostgrestException(
            message: 'permission denied',
            code: ReportsRpcErrorCodes.permissionDenied,
          ),
        ),
      );

      final result = await repository.getOpenInvoicesSource(
        companyId: 'company-1',
        fromDate: null,
        toDate: null,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        ReportsFailureCodes.permissionOpenInvoicesView,
      );
    });

    test('maps auth exceptions to the existing auth-required failure', () async {
      final repository = ReportsRepositoryImpl(
        _FakeReportsRemoteDataSource(error: AuthException('expired')),
      );

      final result = await repository.getOperationalTripSource(
        companyId: 'company-1',
        fromDate: null,
        toDate: null,
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
    });

    test('keeps source mapping inside corrupt-data failure boundary', () async {
      final repository = ReportsRepositoryImpl(
        _FakeReportsRemoteDataSource(
          operationalModel: _operationalModel(currencyCode: 'invalid'),
        ),
      );

      final result = await repository.getOperationalTripSource(
        companyId: 'company-1',
        fromDate: null,
        toDate: null,
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected failures without exposing internal text', () async {
      final repository = ReportsRepositoryImpl(
        _FakeReportsRemoteDataSource(
          error: StateError('secret internal text'),
        ),
      );

      final result = await repository.getTripNetProfitSource(
        companyId: 'company-1',
        fromDate: null,
        toDate: null,
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

ReportSourceMetadataModel _metadata({String currencyCode = 'AED'}) {
  return ReportSourceMetadataModel(
    companyId: 'company-1',
    baseCurrencyCode: currencyCode,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: DateTime(2026, 8, 24),
    fromDate: DateTime(2026, 8, 1),
    toDate: DateTime(2026, 8, 31),
  );
}

OperationalReportSourceModel _operationalModel({
  String currencyCode = 'AED',
}) {
  return OperationalReportSourceModel(
    metadata: _metadata(currencyCode: currencyCode),
    rows: const [],
  );
}

TripExpensesReportSourceModel _tripExpensesModel() {
  return TripExpensesReportSourceModel(
    metadata: _metadata(),
    precisionLossCount: 0,
    negativeAmountCount: 0,
    rows: const [],
  );
}

TripNetProfitReportSourceModel _tripNetProfitModel() {
  return TripNetProfitReportSourceModel(
    metadata: _metadata(),
    freightPrecisionLossCount: 0,
    negativeFreightCount: 0,
    expensePrecisionLossCount: 0,
    negativeExpenseCount: 0,
    trips: const [],
    expenses: const [],
  );
}

OpenInvoicesReportSourceModel _openInvoicesModel() {
  return OpenInvoicesReportSourceModel(
    metadata: _metadata(),
    invoiceCurrencyMismatchCount: 0,
    paymentCurrencyMismatchCount: 0,
    invalidInvoiceAmountCount: 0,
    invalidPaymentAmountCount: 0,
    missingIssueDateCount: 0,
    invoices: const [],
    payments: const [],
  );
}

enum _ReportOperation { operational, tripExpenses, tripNetProfit, openInvoices }

final class _ReportCall {
  final _ReportOperation operation;
  final String companyId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const _ReportCall({
    required this.operation,
    required this.companyId,
    required this.fromDate,
    required this.toDate,
  });
}

final class _FakeReportsRemoteDataSource implements ReportsRemoteDataSource {
  final Object? error;
  final OperationalReportSourceModel operationalModel;
  final TripExpensesReportSourceModel tripExpensesModel;
  final TripNetProfitReportSourceModel tripNetProfitModel;
  final OpenInvoicesReportSourceModel openInvoicesModel;
  final List<_ReportCall> calls = [];

  _FakeReportsRemoteDataSource({
    this.error,
    OperationalReportSourceModel? operationalModel,
    TripExpensesReportSourceModel? tripExpensesModel,
    TripNetProfitReportSourceModel? tripNetProfitModel,
    OpenInvoicesReportSourceModel? openInvoicesModel,
  }) : operationalModel = operationalModel ?? _operationalModel(),
       tripExpensesModel = tripExpensesModel ?? _tripExpensesModel(),
       tripNetProfitModel = tripNetProfitModel ?? _tripNetProfitModel(),
       openInvoicesModel = openInvoicesModel ?? _openInvoicesModel();

  @override
  Future<OperationalReportSourceModel> getOperationalSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    _record(_ReportOperation.operational, companyId, fromDate, toDate);
    _throwIfNeeded();
    return operationalModel;
  }

  @override
  Future<TripExpensesReportSourceModel> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    _record(_ReportOperation.tripExpenses, companyId, fromDate, toDate);
    _throwIfNeeded();
    return tripExpensesModel;
  }

  @override
  Future<TripNetProfitReportSourceModel> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    _record(_ReportOperation.tripNetProfit, companyId, fromDate, toDate);
    _throwIfNeeded();
    return tripNetProfitModel;
  }

  @override
  Future<OpenInvoicesReportSourceModel> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    _record(_ReportOperation.openInvoices, companyId, fromDate, toDate);
    _throwIfNeeded();
    return openInvoicesModel;
  }

  void _record(
    _ReportOperation operation,
    String companyId,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    calls.add(
      _ReportCall(
        operation: operation,
        companyId: companyId,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }

  void _throwIfNeeded() {
    final nextError = error;
    if (nextError != null) throw nextError;
  }
}
