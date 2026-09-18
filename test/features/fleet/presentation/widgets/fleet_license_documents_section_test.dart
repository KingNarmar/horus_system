import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_asset_type.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document_file.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document_file_side.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document_target.dart';
import 'package:horus_system/features/fleet/domain/repositories/fleet_license_documents_repository.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_license_document_usecases.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_license_documents_cubit.dart';
import 'package:horus_system/features/fleet/presentation/widgets/fleet_license_documents_section.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  testWidgets('viewer sees front and back files without mutation actions', (
    tester,
  ) async {
    final repository = _FakeRepository(document: _frontBackDocument);
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);
    await cubit.load(currentCompanyContext: _viewerContext, target: _target);

    await tester.pumpWidget(_app(cubit));

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.fleetLicenseDocumentsTitle), findsOneWidget);
    expect(find.text(l10n.fleetLicenseDocumentFrontSide), findsOneWidget);
    expect(find.text(l10n.fleetLicenseDocumentBackSide), findsOneWidget);
    expect(find.text('front.pdf'), findsOneWidget);
    expect(find.text('back.pdf'), findsOneWidget);
    expect(
      find.byTooltip(l10n.fleetLicenseDocumentOpenButton),
      findsNWidgets(2),
    );
    expect(
      find.byTooltip(l10n.fleetLicenseDocumentDownloadButton),
      findsNWidgets(2),
    );
    expect(
      find.byTooltip(l10n.fleetLicenseDocumentReplaceButton),
      findsNothing,
    );
    expect(find.text(l10n.fleetLicenseDocumentRemoveButton), findsNothing);
  });

  testWidgets('operations sees two upload slots on narrow Arabic RTL layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = const _FakeRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);
    await cubit.load(
      currentCompanyContext: _operationsContext,
      target: _target,
    );

    await tester.pumpWidget(_app(cubit, locale: const Locale('ar')));

    final l10n = AppLocalizationsAr();
    expect(find.text(l10n.fleetLicenseDocumentFrontSide), findsOneWidget);
    expect(find.text(l10n.fleetLicenseDocumentBackSide), findsOneWidget);
    expect(
      find.text(
        l10n.fleetLicenseDocumentUploadSide(l10n.fleetLicenseDocumentFrontSide),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        l10n.fleetLicenseDocumentUploadSide(l10n.fleetLicenseDocumentBackSide),
      ),
      findsOneWidget,
    );
    final context = tester.element(find.byType(FleetLicenseDocumentsSection));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy combined file stays visible as one slot', (tester) async {
    final repository = _FakeRepository(document: _combinedDocument);
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);
    await cubit.load(
      currentCompanyContext: _operationsContext,
      target: _target,
    );

    await tester.pumpWidget(_app(cubit));

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.fleetLicenseDocumentCombinedSide), findsOneWidget);
    expect(find.text('legacy.pdf'), findsOneWidget);
    expect(find.text(l10n.fleetLicenseDocumentFrontSide), findsNothing);
    expect(find.text(l10n.fleetLicenseDocumentBackSide), findsNothing);
  });
}

const _company = Company(id: 'company-1', name: 'Company');
const _viewerContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.viewer,
);
const _operationsContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.operations,
);
const _target = FleetLicenseDocumentTarget(
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
);
final _frontFile = FleetLicenseDocumentFile(
  id: 'front-file',
  companyId: 'company-1',
  licenseDocumentId: 'document-1',
  side: FleetLicenseDocumentFileSide.front,
  originalFileName: 'front.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 100,
  uploadedAt: _uploadedAt,
);
final _backFile = FleetLicenseDocumentFile(
  id: 'back-file',
  companyId: 'company-1',
  licenseDocumentId: 'document-1',
  side: FleetLicenseDocumentFileSide.back,
  originalFileName: 'back.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 100,
  uploadedAt: _uploadedAt,
);
final _combinedFile = FleetLicenseDocumentFile(
  id: 'combined-file',
  companyId: 'company-1',
  licenseDocumentId: 'document-2',
  side: FleetLicenseDocumentFileSide.combined,
  originalFileName: 'legacy.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 100,
  uploadedAt: _uploadedAt,
);
final _frontBackDocument = FleetLicenseDocument(
  id: 'document-1',
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
  files: [_frontFile, _backFile],
  uploadedAt: _uploadedAt,
);
final _combinedDocument = FleetLicenseDocument(
  id: 'document-2',
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
  files: [_combinedFile],
  uploadedAt: _uploadedAt,
);
final _uploadedAt = DateTime.utc(2026, 9, 18);

FleetLicenseDocumentsCubit _createCubit(
  FleetLicenseDocumentsRepository repository,
) {
  return FleetLicenseDocumentsCubit(
    getDocumentUseCase: GetFleetLicenseDocumentUseCase(repository),
    uploadFileUseCase: UploadFleetLicenseDocumentFileUseCase(repository),
    getFileAccessUseCase: GetFleetLicenseDocumentFileAccessUseCase(repository),
    downloadFileUseCase: DownloadFleetLicenseDocumentFileUseCase(repository),
    replaceFileUseCase: ReplaceFleetLicenseDocumentFileUseCase(repository),
    removeDocumentUseCase: RemoveFleetLicenseDocumentUseCase(repository),
    canManageFleetUseCase: const CanManageFleetUseCase(),
  );
}

Widget _app(
  FleetLicenseDocumentsCubit cubit, {
  Locale locale = const Locale('en'),
}) {
  return BlocProvider.value(
    value: cubit,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FleetLicenseDocumentsSection(
          currentLicenseExpiryDate: BusinessDate(
            year: 2027,
            month: 12,
            day: 31,
          ),
          onAssetChanged: () async {},
        ),
      ),
    ),
  );
}

final class _FakeRepository implements FleetLicenseDocumentsRepository {
  final FleetLicenseDocument? document;

  const _FakeRepository({this.document});

  @override
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) async {
    return Success(document);
  }

  @override
  Future<Result<FleetLicenseDocument>> createWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<FleetLicenseDocument>> addFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<FleetLicenseDocument>> replaceFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile replacement,
    BusinessDate? newLicenseExpiryDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  }) async {
    return Success(Uint8List.fromList([1]));
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  }) async {
    return const Success(
      BusinessDocumentAccess('https://example.test/license'),
    );
  }
}
