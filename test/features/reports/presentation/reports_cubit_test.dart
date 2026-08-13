import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/usecases/get_open_invoices_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_operational_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_net_profit_report_usecase.dart';
import 'package:horus_system/features/reports/presentation/cubit/report_type.dart';
import 'package:horus_system/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:horus_system/features/reports/presentation/cubit/reports_state.dart';

void main() {
  test('loads requested operational dimension through use case', () async {
    final repository = _EmptyReportsRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(
      currentCompanyContext: _context,
      reportType: ReportType.tripsByDriver,
    );

    expect(cubit.state, isA<ReportsLoaded>());
    final loaded = cubit.state as ReportsLoaded;
    expect(loaded.reportType, ReportType.tripsByDriver);
    final content = loaded.content as OperationalReportsContent;
    expect(content.report.dimension, OperationalReportDimension.driver);
    expect(repository.operationalCalls, 1);
  });
}

ReportsCubit _cubit(ReportsRepository repository) {
  return ReportsCubit(
    getOperationalReport: GetOperationalReportUseCase(repository: repository),
    getTripExpensesReport: GetTripExpensesReportUseCase(repository),
    getTripNetProfitReport: GetTripNetProfitReportUseCase(
      repository: repository,
    ),
    getOpenInvoicesReport: GetOpenInvoicesReportUseCase(repository: repository),
  );
}

const _context = CurrentCompanyContext(
  company: Company(
    id: 'company-1',
    name: 'Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
  ),
  role: CompanyRole.owner,
);

ReportSourceMetadata _metadata(DateTime? from, DateTime? to) {
  return ReportSourceMetadata(
    companyId: 'company-1',
    currency: CurrencyCode.tryParse('AED')!,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: DateTime(2026, 8, 13),
    fromDate: from,
    toDate: to,
  );
}

final class _EmptyReportsRepository implements ReportsRepository {
  int operationalCalls = 0;

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async {
    operationalCalls++;
    return Success(
      OperationalTripReportSource(
        metadata: _metadata(fromDate, toDate),
        rows: [],
      ),
    );
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async => throw StateError('Unexpected call.');

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async => throw StateError('Unexpected call.');

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) async => throw StateError('Unexpected call.');
}
