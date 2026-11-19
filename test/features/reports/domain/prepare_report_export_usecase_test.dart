import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_logo_file.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_profile.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_branding_repository.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_date_range.dart';
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
      expect(source.calls, 1);
      expect(branding.profileCalls, 1);
    },
  );
}

final class _Source implements ReportsRepository {
  int calls = 0;

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async {
    calls++;
    return Success(
      OperationalTripReportSource(
        metadata: OperationalReportSourceMetadata(
          companyId: companyId,
          businessTimezone: 'Asia/Dubai',
          businessDate: BusinessDate(year: 2026, month: 11, day: 19),
          fromDate: fromDate,
          toDate: toDate,
        ),
        rows: [],
      ),
    );
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw UnimplementedError();

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw UnimplementedError();

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw UnimplementedError();
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
