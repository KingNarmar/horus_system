import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_logo_file.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_profile.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/repositories/company_branding_repository.dart';
import 'package:horus_system/features/reports/domain/entities/open_invoices_report.dart';
import 'package:horus_system/features/reports/domain/entities/operational_trip_report.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_document.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_labels.dart';
import 'package:horus_system/features/reports/domain/entities/report_export_table.dart';
import 'package:horus_system/features/reports/domain/entities/report_source_metadata.dart';
import 'package:horus_system/features/reports/domain/entities/trip_expenses_report.dart';
import 'package:horus_system/features/reports/domain/entities/trip_net_profit_report.dart';
import 'package:horus_system/features/reports/domain/repositories/report_pdf_delivery_repository.dart';
import 'package:horus_system/features/reports/domain/repositories/reports_repository.dart';
import 'package:horus_system/features/reports/domain/services/report_pdf_renderer.dart';
import 'package:horus_system/features/reports/domain/usecases/generate_report_pdf_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_open_invoices_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_operational_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_expenses_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/get_trip_net_profit_report_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/prepare_report_export_usecase.dart';
import 'package:horus_system/features/reports/domain/usecases/report_pdf_delivery_usecases.dart';
import 'package:horus_system/features/reports/presentation/cubit/report_export_cubit.dart';
import 'package:horus_system/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:horus_system/features/reports/presentation/pages/reports_page.dart';
import 'package:horus_system/features/reports/presentation/widgets/report_pdf_preview_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('tenant change closes an already-open PDF preview route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final reportsRepository = _ReportsRepository();
    final reportsCubit = _reportsCubit(reportsRepository);
    final exportCubit = _exportCubit(reportsRepository);
    final networkRepository = _NetworkRepository();
    final networkCubit = NetworkStatusCubit(
      getNetworkStatusUseCase: GetNetworkStatusUseCase(networkRepository),
      watchNetworkStatusUseCase: WatchNetworkStatusUseCase(networkRepository),
      pollingEnabled: false,
    );
    addTearDown(networkCubit.close);
    addTearDown(reportsCubit.close);
    addTearDown(exportCubit.close);

    await tester.pumpWidget(
      _app(
        'company-a',
        reportsCubit: reportsCubit,
        exportCubit: exportCubit,
        networkCubit: networkCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview PDF'), findsOneWidget);
    await tester.tap(find.text('Preview PDF'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ReportPdfPreviewDialog), findsOneWidget);

    await tester.pumpWidget(
      _app(
        'company-b',
        reportsCubit: reportsCubit,
        exportCubit: exportCubit,
        networkCubit: networkCubit,
      ),
    );
    await tester.pump();

    expect(find.byType(ReportPdfPreviewDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  String companyId, {
  required ReportsCubit reportsCubit,
  required ReportExportCubit exportCubit,
  required NetworkStatusCubit networkCubit,
}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MultiBlocProvider(
    providers: [
      BlocProvider<ReportsCubit>.value(value: reportsCubit),
      BlocProvider<ReportExportCubit>.value(value: exportCubit),
      BlocProvider<NetworkStatusCubit>.value(value: networkCubit),
    ],
    child: Scaffold(
      body: SingleChildScrollView(
        child: ReportsPage(
          currentCompanyContext: CurrentCompanyContext(
            company: Company(
              id: companyId,
              name: companyId,
              businessTimezone: 'Asia/Dubai',
            ),
            role: CompanyRole.owner,
          ),
        ),
      ),
    ),
  ),
);

ReportsCubit _reportsCubit(ReportsRepository repository) => ReportsCubit(
  getOperationalReport: GetOperationalReportUseCase(repository: repository),
  getTripExpensesReport: GetTripExpensesReportUseCase(repository),
  getTripNetProfitReport: GetTripNetProfitReportUseCase(repository: repository),
  getOpenInvoicesReport: GetOpenInvoicesReportUseCase(repository: repository),
);

ReportExportCubit _exportCubit(ReportsRepository repository) {
  final prepare = PrepareReportExportUseCase(
    operational: GetOperationalReportUseCase(repository: repository),
    expenses: GetTripExpensesReportUseCase(repository),
    profit: GetTripNetProfitReportUseCase(repository: repository),
    invoices: GetOpenInvoicesReportUseCase(repository: repository),
    branding: _Branding(),
    clock: () => DateTime.utc(2026, 11, 19),
  );
  final delivery = _Delivery();
  return ReportExportCubit(
    generate: GenerateReportPdfUseCase(prepare: prepare, renderer: _Renderer()),
    save: SaveReportPdfUseCase(delivery),
    print: PrintReportPdfUseCase(delivery),
    share: ShareReportPdfUseCase(delivery),
  );
}

final class _ReportsRepository implements ReportsRepository {
  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) async => Success(
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

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected expense report.');

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected profit report.');

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required BusinessDate? fromDate,
    required BusinessDate? toDate,
  }) => throw StateError('Unexpected invoices report.');
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
  }) => throw StateError('Unexpected logo download.');

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
  }) => throw StateError('Unexpected company write.');

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) => throw StateError('Unexpected logo write.');

  @override
  Future<Result<CompanyBrandProfile>> removeLogo({
    required String companyId,
    required String? expectedLogoPath,
  }) => throw StateError('Unexpected logo write.');
}

final class _NetworkRepository implements NetworkStatusRepository {
  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async =>
      const Success(NetworkConnectionStatus.online);

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() =>
      Stream<Result<NetworkConnectionStatus>>.value(
        const Success(NetworkConnectionStatus.online),
      );
}

final class _Renderer implements ReportPdfRenderer {
  @override
  Future<Result<Uint8List>> render({
    required ReportExportDocument document,
    required ReportExportTable table,
    required ReportExportLabels labels,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Text('Report preview')));
    return Success(await pdf.save());
  }
}

final class _Delivery implements ReportPdfDeliveryRepository {
  @override
  Future<Result<ReportPdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  }) async => const Success(ReportPdfDeliveryOutcome.completed);

  @override
  Future<Result<ReportPdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
  }) async => const Success(ReportPdfDeliveryOutcome.completed);

  @override
  Future<Result<ReportPdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  }) async => const Success(ReportPdfDeliveryOutcome.completed);
}
