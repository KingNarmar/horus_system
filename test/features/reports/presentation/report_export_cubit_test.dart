import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/common_failures.dart';
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
import 'package:horus_system/features/reports/domain/entities/report_export_document.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_kind.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_labels.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_progress.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_pdf_page_layout.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:horus_system/features/reports/domain/repositories/report_pdf_delivery_repository.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/services/report_pdf_renderer.dart';
import 'package:horus_system/features/reports/domain/usecases/generate_report_pdf_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_open_invoices_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_operational_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_net_profit_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/prepare_report_export_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/reauthorize_report_pdf_print_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/report_pdf_delivery_usecases.dart';
import 'package:horus_system/features/reports/presentation/cubit/report_export_cubit.dart';
import 'package:horus_system/features/reports/presentation/cubit/report_export_state.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  test('empty reports block all PDF actions before rendering or delivery', () async {
    for (final action in ReportPdfAction.values) {
      final source = _PendingReportSource();
      final renderer = _RecordingRenderer();
      final delivery = _RecordingDelivery();
      final cubit = _createCubit(source, renderer, delivery);

      final request = cubit.perform(
        action: action,
        currentCompanyContext: _context('company-a', CompanyRole.owner),
        kind: ReportExportKind.dailyTrips,
        dateRange: const ReportDateRange(),
        labels: _labels(),
      );
      source.complete('company-a', empty: true);
      await request;

      final failed = cubit.state as ReportExportFailed;
      expect(failed.failure.code, ReportsFailureCodes.exportNoData);
      expect(renderer.renderedCompanies, isEmpty);
      expect(delivery.calls, 0);
      await cubit.close();
    }
  });

  test('invalidating a pending export discards its PDF', () async {
    final source = _PendingReportSource();
    final renderer = _RecordingRenderer();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, renderer, delivery);
    addTearDown(cubit.close);

    final request = _preview(cubit, 'company-a');
    expect(cubit.state, isA<ReportExportBusy>());
    expect(source.requestedCompanies, ['company-a']);

    cubit.invalidate();
    source.complete('company-a');
    await request;

    expect(cubit.state, isA<ReportExportIdle>());
    expect(renderer.renderedCompanies, isEmpty);
    expect(delivery.calls, 0);
  });

  test('explicit cancellation prevents late report and PDF delivery', () async {
    final source = _PendingReportSource();
    final renderer = _RecordingRenderer();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, renderer, delivery);
    addTearDown(cubit.close);

    final request = _preview(cubit, 'company-a');
    expect(cubit.state, isA<ReportExportBusy>());

    cubit.cancelActive();
    expect(cubit.state, isA<ReportExportIdle>());

    source.complete('company-a');
    await request;

    expect(cubit.state, isA<ReportExportIdle>());
    expect(renderer.renderedCompanies, isEmpty);
    expect(delivery.calls, 0);
  });

  test('reports real source, branding and render phases', () async {
    final source = _PendingReportSource();
    final cubit = _createCubit(
      source,
      _RecordingRenderer(),
      _RecordingDelivery(),
    );
    addTearDown(cubit.close);
    final stages = <ReportExportStage>[];
    final subscription = cubit.stream.listen((state) {
      if (state is ReportExportBusy) stages.add(state.progress.stage);
    });
    addTearDown(subscription.cancel);

    final request = _preview(cubit, 'company-a');
    expect(
      (cubit.state as ReportExportBusy).progress.stage,
      ReportExportStage.readingSource,
    );
    source.complete('company-a');
    await request;

    expect(
      stages,
      containsAllInOrder([
        ReportExportStage.loadingBranding,
        ReportExportStage.renderingPdf,
      ]),
    );
    expect(cubit.state, isA<ReportExportPreviewReady>());
  });

  test('a late old-tenant response cannot overwrite new-tenant PDF', () async {
    final source = _PendingReportSource();
    final renderer = _RecordingRenderer();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, renderer, delivery);
    addTearDown(cubit.close);

    final oldRequest = _preview(cubit, 'company-a');
    cubit.invalidate();
    final newRequest = _preview(cubit, 'company-b');

    source.complete('company-b');
    await newRequest;
    final ready = cubit.state;
    expect(ready, isA<ReportExportPreviewReady>());
    expect((ready as ReportExportPreviewReady).bytes, renderer.pdfBytes);

    source.complete('company-a');
    await oldRequest;
    expect(cubit.state, same(ready));
    expect(renderer.renderedCompanies, ['company-b']);
    expect(delivery.calls, 0);
  });

  test(
    'unauthorized driver is denied before data access or rendering',
    () async {
      final source = _PendingReportSource();
      final renderer = _RecordingRenderer();
      final delivery = _RecordingDelivery();
      final cubit = _createCubit(source, renderer, delivery);
      addTearDown(cubit.close);

      await cubit.perform(
        action: ReportPdfAction.preview,
        currentCompanyContext: _context('company-a', CompanyRole.driver),
        kind: ReportExportKind.dailyTrips,
        dateRange: const ReportDateRange(),
        labels: _labels(),
      );

      expect(
        (cubit.state as ReportExportFailed).failure.code,
        ReportsFailureCodes.permissionExport,
      );
      expect(source.requestedCompanies, isEmpty);
      expect(renderer.renderedCompanies, isEmpty);
      expect(delivery.calls, 0);
    },
  );

  test('while an export is busy, repeated actions are ignored', () async {
    final source = _PendingReportSource();
    final renderer = _RecordingRenderer();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, renderer, delivery);
    addTearDown(cubit.close);

    final first = cubit.perform(
      action: ReportPdfAction.save,
      currentCompanyContext: _context('company-a', CompanyRole.owner),
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      labels: _labels(),
    );
    await cubit.perform(
      action: ReportPdfAction.save,
      currentCompanyContext: _context('company-a', CompanyRole.owner),
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      labels: _labels(),
    );
    expect(source.requestedCompanies, ['company-a']);
    expect(cubit.state, isA<ReportExportBusy>());

    source.complete('company-a');
    await first;
    expect(cubit.state, isA<ReportExportCompleted>());
    expect(delivery.calls, 1);
    expect(renderer.renderedCompanies, ['company-a']);
  });

  test(
    'Print requires preview and fresh authorization before native delivery',
    () async {
      final source = _PendingReportSource();
      final renderer = _RecordingRenderer();
      final delivery = _RecordingDelivery();
      final cubit = _createCubit(source, renderer, delivery);
      addTearDown(cubit.close);

      final request = cubit.perform(
        action: ReportPdfAction.print,
        currentCompanyContext: _context('company-a', CompanyRole.owner),
        kind: ReportExportKind.dailyTrips,
        dateRange: const ReportDateRange(),
        labels: _labels(),
      );
      source.complete('company-a');
      await request;

      final ready = cubit.state as ReportExportPrintPreviewReady;
      expect(ready.document.bytes, same(renderer.pdfBytes));
      expect(ready.document.pageLayout, ReportPdfPageLayout.a4Landscape);
      expect(delivery.printCalls, 0);

      final confirmed = cubit.confirmPrint(
        currentCompanyContext: _context('company-a', CompanyRole.owner),
      );
      expect(source.requestedCompanies, ['company-a', 'company-a']);
      expect(delivery.printCalls, 0);
      source.complete('company-a');
      await confirmed;

      expect(cubit.state, isA<ReportExportCompleted>());
      expect(delivery.printCalls, 1);
      expect(delivery.lastPrintedBytes, same(ready.document.bytes));
      expect(delivery.lastPageLayout, ready.document.pageLayout);
    },
  );

  test('closing print preview prevents any printer invocation', () async {
    final source = _PendingReportSource();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, _RecordingRenderer(), delivery);
    addTearDown(cubit.close);
    final request = cubit.perform(
      action: ReportPdfAction.print,
      currentCompanyContext: _context('company-a', CompanyRole.owner),
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      labels: _labels(),
    );
    source.complete('company-a');
    await request;
    cubit.cancelPrintPreview();
    await cubit.confirmPrint(
      currentCompanyContext: _context('company-a', CompanyRole.owner),
    );
    expect(cubit.state, isA<ReportExportIdle>());
    expect(source.requestedCompanies, ['company-a']);
    expect(delivery.printCalls, 0);
  });

  test('print confirmation is refused after a tenant context change', () async {
    final source = _PendingReportSource();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, _RecordingRenderer(), delivery);
    addTearDown(cubit.close);
    final request = cubit.perform(
      action: ReportPdfAction.print,
      currentCompanyContext: _context('company-a', CompanyRole.owner),
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      labels: _labels(),
    );
    source.complete('company-a');
    await request;
    await cubit.confirmPrint(
      currentCompanyContext: _context('company-b', CompanyRole.owner),
    );
    expect(cubit.state, isA<ReportExportIdle>());
    expect(source.requestedCompanies, ['company-a']);
    expect(delivery.printCalls, 0);
  });

  test('permission revoked before confirmation blocks delivery', () async {
    final source = _PendingReportSource();
    final delivery = _RecordingDelivery();
    final cubit = _createCubit(source, _RecordingRenderer(), delivery);
    addTearDown(cubit.close);
    final request = cubit.perform(
      action: ReportPdfAction.print,
      currentCompanyContext: _context('company-a', CompanyRole.owner),
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      labels: _labels(),
    );
    source.complete('company-a');
    await request;

    final confirmed = cubit.confirmPrint(
      currentCompanyContext: _context('company-a', CompanyRole.owner),
    );
    source.deny('company-a');
    await confirmed;

    expect(cubit.state, isA<ReportExportFailed>());
    expect(delivery.printCalls, 0);
  });
}

Future<void> _preview(ReportExportCubit cubit, String companyId) =>
    cubit.perform(
      action: ReportPdfAction.preview,
      currentCompanyContext: _context(companyId, CompanyRole.owner),
      kind: ReportExportKind.dailyTrips,
      dateRange: const ReportDateRange(),
      labels: _labels(),
    );

CurrentCompanyContext _context(String companyId, CompanyRole role) =>
    CurrentCompanyContext(
      company: Company(
        id: companyId,
        name: companyId,
        businessTimezone: 'Asia/Dubai',
      ),
      role: role,
    );

ReportExportLabels _labels() => ReportExportLabels(
  isRtl: false,
  localeName: 'en',
  period: 'Period',
  generatedAt: 'Generated',
  sourceAsOf: 'Source read (server)',
  page: 'Page',
  noRows: 'No rows',
  allDates: 'All dates',
  unassigned: 'Unassigned',
  unavailable: 'N/A',
  titles: const {},
  columns: const {},
  tripStatuses: const {},
  invoiceStatuses: const {},
  fundingSources: const {},
);

ReportExportCubit _createCubit(
  _PendingReportSource source,
  _RecordingRenderer renderer,
  _RecordingDelivery delivery,
) {
  final prepare = PrepareReportExportUseCase(
    operational: GetOperationalReportUseCase(repository: source),
    expenses: GetTripExpensesReportUseCase(source),
    profit: GetTripNetProfitReportUseCase(repository: source),
    invoices: GetOpenInvoicesReportUseCase(repository: source),
    branding: _Branding(),
    clock: () => DateTime.utc(2026, 11, 19),
  );
  return ReportExportCubit(
    generate: GenerateReportPdfUseCase(prepare: prepare, renderer: renderer),
    reauthorizePrint: ReauthorizeReportPdfPrintUseCase(prepare),
    save: SaveReportPdfUseCase(delivery),
    print: PrintReportPdfUseCase(delivery),
    share: ShareReportPdfUseCase(delivery),
  );
}

final class _PendingReportSource implements ReportsRepository {
  final Map<String, Completer<Result<OperationalTripReportSource>>> _pending =
      {};
  final List<String> requestedCompanies = [];

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) {
    requestedCompanies.add(companyId);
    final completer = Completer<Result<OperationalTripReportSource>>();
    _pending[companyId] = completer;
    return completer.future;
  }

  void deny(String companyId) => _pending[companyId]!.complete(
    const FailureResult(
      PermissionFailure(code: ReportsFailureCodes.permissionExport),
    ),
  );

  void complete(String companyId, {bool empty = false}) {
    _pending[companyId]!.complete(
      Success(
        OperationalTripReportSource(
          metadata: OperationalReportSourceMetadata(
            companyId: companyId,
            businessTimezone: 'Asia/Dubai',
            businessDate: BusinessDate(year: 2026, month: 11, day: 19),
            fromDate: null,
            toDate: null,
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
      ),
    );
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected financial source call.');

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected financial source call.');

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected financial source call.');
}

final class _Branding implements CompanyBrandingRepository {
  @override
  Future<Result<CompanyBrandProfile>> getProfile(String companyId) async =>
      Success(
        CompanyBrandProfile(
          companyId: companyId,
          name: companyId,
          updatedAt: DateTime.utc(2026, 11, 19),
        ),
      );

  @override
  Future<Result<Uint8List>> downloadLogo({
    required String companyId,
    required String storagePath,
  }) => throw StateError('Unexpected logo request.');

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
  }) => throw StateError('Unexpected brand write.');

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) => throw StateError('Unexpected brand write.');

  @override
  Future<Result<CompanyBrandProfile>> removeLogo({
    required String companyId,
    required String? expectedLogoPath,
  }) => throw StateError('Unexpected brand write.');
}

final class _RecordingRenderer implements ReportPdfRenderer {
  final List<String> renderedCompanies = [];
  final Uint8List pdfBytes = Uint8List.fromList([37, 80, 68, 70]);

  @override
  Future<Result<Uint8List>> render({
    required ReportExportDocument document,
    required ReportExportTable table,
    required ReportExportLabels labels,
    required ReportPdfPageLayout pageLayout,
  }) async {
    renderedCompanies.add(document.companyId);
    return Success(pdfBytes);
  }
}

final class _RecordingDelivery implements ReportPdfDeliveryRepository {
  int calls = 0;
  int printCalls = 0;
  Uint8List? lastPrintedBytes;
  ReportPdfPageLayout? lastPageLayout;

  @override
  Future<Result<ReportPdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    calls++;
    return const Success(ReportPdfDeliveryOutcome.completed);
  }

  @override
  Future<Result<ReportPdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
    required ReportPdfPageLayout pageLayout,
  }) async {
    calls++;
    printCalls++;
    lastPrintedBytes = bytes;
    lastPageLayout = pageLayout;
    return const Success(ReportPdfDeliveryOutcome.completed);
  }

  @override
  Future<Result<ReportPdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    calls++;
    return const Success(ReportPdfDeliveryOutcome.completed);
  }
}
