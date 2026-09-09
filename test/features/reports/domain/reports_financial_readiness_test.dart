import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/usecases/get_operational_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/report_params.dart';
import 'package:test/test.dart';

void main() {
  test('operational report works when base currency is not configured', () async {
    final repository = _ReadinessReportsRepository();
    final useCase = GetOperationalReportUseCase(repository: repository);

    final result = await useCase(
      OperationalReportParams(
        currentCompanyContext: _context(CompanyRole.viewer),
        dimension: OperationalReportDimension.day,
        dateRange: const ReportDateRange(),
      ),
    );

    expect(result, isA<Success<OperationalTripReport>>());
    expect(repository.operationalCalls, 1);
    expect(result.dataOrNull?.metadata.currency, isNull);
    expect(result.dataOrNull?.metadata.baseCurrencyFractionDigits, isNull);
  });

  test(
    'financial report fails before repository access when currency is missing',
    () async {
      final repository = _ReadinessReportsRepository();
      final useCase = GetTripExpensesReportUseCase(repository);

      final result = await useCase(
        ReportParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          dateRange: const ReportDateRange(),
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
      expect(repository.expenseCalls, 0);
    },
  );
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Horus Transport',
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

final class _ReadinessReportsRepository implements ReportsRepository {
  int operationalCalls = 0;
  int expenseCalls = 0;

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    operationalCalls++;
    return Success(
      OperationalTripReportSource(
        metadata: ReportSourceMetadata(
          companyId: companyId,
          currency: null,
          baseCurrencyFractionDigits: null,
          businessTimezone: 'Asia/Dubai',
          businessDate: DateTime(2026, 9, 9),
          fromDate: fromDate,
          toDate: toDate,
        ),
        rows: const [],
      ),
    );
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    expenseCalls++;
    throw StateError('Financial report repository must not be called.');
  }

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    throw StateError('Unexpected net-profit report call.');
  }

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    throw StateError('Unexpected open-invoices report call.');
  }
}
