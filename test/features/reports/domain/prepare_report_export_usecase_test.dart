import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_logo_file.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_profile.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_branding_repository.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_funding_source.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_cancellation.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/usecases/get_open_invoices_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_operational_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_net_profit_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/prepare_report_export_usecase.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  final clock = DateTime.utc(2026, 11, 19, 8, 30);

  PrepareReportExportUseCase create(_Source source, _Branding branding) =>
      PrepareReportExportUseCase(
        operational: GetOperationalReportUseCase(repository: source),
        expenses: GetTripExpensesReportUseCase(source),
        profit: GetTripNetProfitReportUseCase(repository: source),
        invoices: GetOpenInvoicesReportUseCase(repository: source),
        branding: branding,
        clock: () => clock,
      );

  PrepareReportExportParams request(CompanyRole role, ReportExportKind kind) =>
      PrepareReportExportParams(
        currentCompanyContext: CurrentCompanyContext(
          company: const Company(
            id: 'company-a',
            name: 'Tenant A',
            baseCurrencyCode: 'AED',
            baseCurrencyFractionDigits: 2,
            businessTimezone: 'Asia/Dubai',
          ),
          role: role,
        ),
        kind: kind,
        dateRange: const ReportDateRange(),
      );

  test('driver denied before any backend or branding access', () async {
    final source = _Source();
    final branding = _Branding();
    final result = await create(source, branding)(
      request(CompanyRole.driver, ReportExportKind.dailyTrips),
    );
    expect(result.failureOrNull?.code, ReportsFailureCodes.permissionExport);
    expect(source.calls, 0);
    expect(branding.profileCalls, 0);
  });

  test('viewer denied finance export before any backend access', () async {
    final source = _Source();
    final branding = _Branding();
    final result = await create(source, branding)(
      request(CompanyRole.viewer, ReportExportKind.tripNetProfit),
    );
    expect(result.failureOrNull?.code, ReportsFailureCodes.permissionExport);
    expect(source.calls, 0);
    expect(branding.profileCalls, 0);
  });

  test('export uses paged source without changing screen reads', () async {
    final screenSource = _Source();
    final pagedSource = _Source();
    final branding = _Branding();
    final cancellation = ReportExportCancellation();
    var factoryCalls = 0;
    final prepare = PrepareReportExportUseCase(
      operational: GetOperationalReportUseCase(repository: screenSource),
      expenses: GetTripExpensesReportUseCase(screenSource),
      profit: GetTripNetProfitReportUseCase(repository: screenSource),
      invoices: GetOpenInvoicesReportUseCase(repository: screenSource),
      branding: branding,
      clock: () => clock,
      exportSourcesFactory: ({required cancellation, onProgress}) {
        factoryCalls++;
        return pagedSource;
      },
    );

    final requested = request(
      CompanyRole.operations,
      ReportExportKind.dailyTrips,
    );
    final result = await prepare(
      PrepareReportExportParams(
        currentCompanyContext: requested.currentCompanyContext,
        kind: requested.kind,
        dateRange: requested.dateRange,
        cancellation: cancellation,
      ),
    );
    expect(result.failureOrNull, isNull);
    expect(factoryCalls, 1);
    expect(screenSource.calls, 0);
    expect(pagedSource.calls, 1);
  });

  for (final kind in ReportExportKind.values) {
    test('empty ${kind.name} export stops before branding', () async {
      final source = _Source(empty: true);
      final branding = _Branding();
      final result = await create(source, branding)(
        request(CompanyRole.owner, kind),
      );
      expect(result.failureOrNull?.code, ReportsFailureCodes.exportNoData);
      expect(result.dataOrNull, isNull);
      expect(source.calls, 1);
      expect(branding.profileCalls, 0);
    });

    test('nonempty ${kind.name} still exports', () async {
      final source = _Source();
      final branding = _Branding();
      final result = await create(source, branding)(
        request(CompanyRole.owner, kind),
      );
      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, isNotNull);
      expect(source.calls, 1);
      expect(branding.profileCalls, 1);
      if (kind == ReportExportKind.tripExpenses) {
        final content = result.dataOrNull!.content as ReportExportExpensesContent;
        expect(content.report.rows, hasLength(1));
        // A real row with zero financial amount is not an empty report.
        expect(content.report.totalExpenses.minorUnits, 0);
      }
    });
  }

  test('backend permission failures cannot be masked as empty exports', () async {
    final source = _Source(failFromBackend: true);
    final branding = _Branding();
    final result = await create(source, branding)(
      request(CompanyRole.owner, ReportExportKind.dailyTrips),
    );
    expect(
      result.failureOrNull?.code,
      ReportsFailureCodes.permissionOperationalView,
    );
    expect(source.calls, 1);
    expect(branding.profileCalls, 0);
  });

  test('foreign tenant branding identity fails closed', () async {
    final source = _Source();
    final branding = _Branding(companyId: 'company-b');
    final result = await create(source, branding)(
      request(CompanyRole.viewer, ReportExportKind.dailyTrips),
    );
    expect(result.failureOrNull?.code, ReportsFailureCodes.permissionExport);
    expect(source.calls, 1);
    expect(branding.profileCalls, 1);
  });

  test(
    'authorized operational export refreshes source and trusted scope',
    () async {
      final source = _Source();
      final branding = _Branding();
      final result = await create(source, branding)(
        request(CompanyRole.operations, ReportExportKind.dailyTrips),
      );
      final document = result.dataOrNull;
      expect(result.failureOrNull, isNull);
      expect(document?.companyId, 'company-a');
      expect(document?.companyName, 'Tenant A');
      expect(document?.generatedAtUtc, clock);
      expect(document?.sourceAsOfUtc, DateTime.utc(2026, 11, 19, 8, 20));
      expect(source.calls, 1);
      expect(branding.profileCalls, 1);
    },
  );
}

final class _Source implements ReportsRepository {
  final bool empty;
  final bool failFromBackend;
  int calls = 0;

  _Source({this.empty = false, this.failFromBackend = false});

  ReportSourceMetadata _financialMetadata(
    String companyId,
    BusinessDate? fromDate,
    BusinessDate? toDate,
  ) => ReportSourceMetadata(
    companyId: companyId,
    currency: CurrencyCode.tryParse('AED')!,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: BusinessDate(year: 2026, month: 11, day: 19),
    sourceAsOfUtc: DateTime.utc(2026, 11, 19, 8, 20),
    fromDate: fromDate,
    toDate: toDate,
  );

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    calls++;
    if (failFromBackend) {
      return const FailureResult(
        PermissionFailure(code: ReportsFailureCodes.permissionOperationalView),
      );
    }
    return Success(
      OperationalTripReportSource(
        metadata: OperationalReportSourceMetadata(
          companyId: companyId,
          businessTimezone: 'Asia/Dubai',
          businessDate: BusinessDate(year: 2026, month: 11, day: 19),
          sourceAsOfUtc: DateTime.utc(2026, 11, 19, 8, 20),
          fromDate: fromDate,
          toDate: toDate,
        ),
        rows: [
          if (!empty)
            OperationalTripReportRow(
              tripId: 'trip-a',
              tripNumber: 'TRIP-A',
              operationalDate: BusinessDate(year: 2026, month: 11, day: 19),
              status: TripStatus.created,
              customerId: 'customer-a',
              customerName: 'Customer A',
              driverId: null,
              driverName: null,
              tractorHeadId: null,
              tractorHeadPlateNumber: null,
              trailerId: null,
              trailerPlateNumber: null,
              routeId: 'route-a',
              loadingLocation: 'Dubai',
              unloadingLocation: 'Port',
              loadingOrderNumber: null,
              waybillNumber: null,
              cargoType: null,
              quantityTons: null,
            ),
        ],
      ),
    );
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    calls++;
    return Success(
      TripExpensesReportSource(
        metadata: _financialMetadata(companyId, fromDate, toDate),
        precisionLossCount: 0,
        negativeAmountCount: 0,
        currencyMismatchCount: 0,
        rows: [
          if (!empty)
            TripExpenseReportRow(
              expenseId: 'expense-a',
              expenseDate: BusinessDate(year: 2026, month: 11, day: 19),
              tripId: 'trip-a',
              tripNumber: 'TRIP-A',
              tripDate: BusinessDate(year: 2026, month: 11, day: 19),
              customerId: 'customer-a',
              customerName: 'Customer A',
              loadingLocation: 'Dubai',
              unloadingLocation: 'Port',
              loadingOrderNumber: null,
              waybillNumber: null,
              expenseTypeId: 'fuel',
              expenseName: 'Fuel',
              fundingSource: ExpenseFundingSource.company,
              amount: Money(
                minorUnits: 0,
                currency: CurrencyCode.tryParse('AED')!,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    calls++;
    return Success(
      TripNetProfitReportSource(
        metadata: _financialMetadata(companyId, fromDate, toDate),
        freightPrecisionLossCount: 0,
        negativeFreightCount: 0,
        expensePrecisionLossCount: 0,
        negativeExpenseCount: 0,
        expenseCurrencyMismatchCount: 0,
        trips: [
          if (!empty)
            TripNetProfitSourceTrip(
              tripId: 'trip-a',
              tripNumber: 'TRIP-A',
              operationalDate: BusinessDate(year: 2026, month: 11, day: 19),
              status: TripStatus.created,
              customerId: 'customer-a',
              customerName: 'Customer A',
              driverId: null,
              driverName: null,
              tractorHeadId: null,
              tractorHeadPlateNumber: null,
              trailerId: null,
              trailerPlateNumber: null,
              loadingLocation: 'Dubai',
              unloadingLocation: 'Port',
              loadingOrderNumber: null,
              waybillNumber: null,
              freight: Money(
                minorUnits: 0,
                currency: CurrencyCode.tryParse('AED')!,
              ),
            ),
        ],
        expenses: [],
      ),
    );
  }

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    calls++;
    return Success(
      OpenInvoicesReportSource(
        metadata: _financialMetadata(companyId, fromDate, toDate),
        invoiceCurrencyMismatchCount: 0,
        paymentCurrencyMismatchCount: 0,
        invalidInvoiceAmountCount: 0,
        invalidPaymentAmountCount: 0,
        missingIssueDateCount: 0,
        invoices: [
          if (!empty)
            OpenInvoiceSourceInvoice(
              invoiceId: 'invoice-a',
              invoiceNumber: 'INV-A',
              customerId: 'customer-a',
              customerName: 'Customer A',
              status: InvoiceStatus.issued,
              total: Money(
                minorUnits: 100,
                currency: CurrencyCode.tryParse('AED')!,
              ),
              issueDate: BusinessDate(year: 2026, month: 11, day: 19),
              dueDate: null,
              issuedAt: null,
            ),
        ],
        payments: [],
      ),
    );
  }
}

final class _Branding implements CompanyBrandingRepository {
  final String companyId;
  int profileCalls = 0;

  _Branding({this.companyId = 'company-a'});

  @override
  Future<Result<CompanyBrandProfile>> getProfile(String companyId) async {
    profileCalls++;
    return Success(
      CompanyBrandProfile(
        companyId: this.companyId,
        name: 'Tenant A',
        updatedAt: DateTime.utc(2026, 11, 19),
      ),
    );
  }

  @override
  Future<Result<Uint8List>> downloadLogo({
    required String companyId,
    required String storagePath,
  }) => throw UnimplementedError();

  @override
  Future<Result<CompanyBrandProfile>> updateProfile({
    required String companyId,
    required DateTime expectedUpdatedAt,
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
    String? address,
    String? taxRegistrationNumber,
  }) => throw UnimplementedError();

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) => throw UnimplementedError();

  @override
  Future<Result<CompanyBrandProfile>> removeLogo({
    required String companyId,
    required String? expectedLogoPath,
  }) => throw UnimplementedError();
}
