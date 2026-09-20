import 'dart:typed_data';

import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/errors/common_failures.dart';
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
import 'package:horus_system/features/fleet/presentation/cubit/fleet_license_documents_state.dart';
import 'package:test/test.dart';

void main() {
  group('FleetLicenseDocumentsCubit', () {
    test('load exposes active document and management permission', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.load(
        currentCompanyContext: _operationsContext,
        target: _target,
      );

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(state.document?.frontFile?.id, _frontFile.id);
      expect(state.canManage, isTrue);
      expect(state.isMutating, isFalse);
      expect(state.failure, isNull);
    });

    test('viewer load remains read-only', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.load(currentCompanyContext: _viewerContext, target: _target);

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(state.document?.id, _frontDocument.id);
      expect(state.canManage, isFalse);
    });

    test(
      'successful back upload replaces state with aggregate result',
      () async {
        final repository = _FakeRepository()
          ..activeDocument = _frontDocument
          ..addResult = Success(_frontBackDocument);
        final cubit = _createCubit(repository);
        addTearDown(cubit.close);

        await cubit.load(
          currentCompanyContext: _operationsContext,
          target: _target,
        );
        final changed = await cubit.upload(
          side: FleetLicenseDocumentFileSide.back,
          file: _businessFile,
        );

        final state = cubit.state as FleetLicenseDocumentsLoaded;
        expect(changed, isTrue);
        expect(state.document?.frontFile, isNotNull);
        expect(state.document?.backFile, isNotNull);
        expect(state.failure, isNull);
      },
    );

    test('trusted-date failure blocks document upload', () async {
      const failure = UnexpectedFailure(message: 'offline');
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final cubit = _createCubit(
        repository,
        businessDateProvider: _FakeBusinessDateProvider(failure: failure),
      );
      addTearDown(cubit.close);

      await cubit.load(
        currentCompanyContext: _operationsContext,
        target: _target,
      );
      final changed = await cubit.upload(
        side: FleetLicenseDocumentFileSide.back,
        file: _businessFile,
      );

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(changed, isFalse);
      expect(state.failure, same(failure));
      expect(state.isMutating, isFalse);
      expect(repository.addCalls, 0);
    });

    test(
      'failed remove preserves document and exposes typed failure',
      () async {
        const failure = ServerFailure(
          code: 'fleet_license_document_server_error',
        );
        final repository = _FakeRepository()
          ..activeDocument = _frontDocument
          ..removeResult = const FailureResult<void>(failure);
        final cubit = _createCubit(repository);
        addTearDown(cubit.close);

        await cubit.load(
          currentCompanyContext: _operationsContext,
          target: _target,
        );
        final changed = await cubit.remove(_frontDocument);

        final state = cubit.state as FleetLicenseDocumentsLoaded;
        expect(changed, isFalse);
        expect(state.document?.id, _frontDocument.id);
        expect(state.failure, same(failure));
        expect(state.isMutating, isFalse);
      },
    );
  });
}

const _company = Company(id: 'company-1', name: 'Company');
const _operationsContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.operations,
);
const _viewerContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.viewer,
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
  sizeBytes: 3,
  uploadedAt: _uploadedAt,
);
final _backFile = FleetLicenseDocumentFile(
  id: 'back-file',
  companyId: 'company-1',
  licenseDocumentId: 'document-1',
  side: FleetLicenseDocumentFileSide.back,
  originalFileName: 'back.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 3,
  uploadedAt: _uploadedAt,
);
final _frontDocument = FleetLicenseDocument(
  id: 'document-1',
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
  files: [_frontFile],
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
final _uploadedAt = DateTime.utc(2026, 9, 18);

final _businessFile = BusinessDocumentFile(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'back.pdf',
  mimeType: 'application/pdf',
);

FleetLicenseDocumentsCubit _createCubit(
  FleetLicenseDocumentsRepository repository, {
  CompanyBusinessDateProvider? businessDateProvider,
}) {
  return FleetLicenseDocumentsCubit(
    getDocumentUseCase: GetFleetLicenseDocumentUseCase(repository),
    uploadFileUseCase: UploadFleetLicenseDocumentFileUseCase(repository),
    getFileAccessUseCase: GetFleetLicenseDocumentFileAccessUseCase(repository),
    downloadFileUseCase: DownloadFleetLicenseDocumentFileUseCase(repository),
    replaceFileUseCase: ReplaceFleetLicenseDocumentFileUseCase(repository),
    removeDocumentUseCase: RemoveFleetLicenseDocumentUseCase(repository),
    canManageFleetUseCase: const CanManageFleetUseCase(),
    getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
      businessDateProvider ?? _FakeBusinessDateProvider(),
    ),
  );
}

final class _FakeRepository implements FleetLicenseDocumentsRepository {
  FleetLicenseDocument? activeDocument;
  Result<FleetLicenseDocument> addResult = Success(_frontDocument);
  Result<void> removeResult = const Success<void>(null);
  int addCalls = 0;

  @override
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) async {
    return Success(activeDocument);
  }

  @override
  Future<Result<FleetLicenseDocument>> createWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    return Success(_frontDocument);
  }

  @override
  Future<Result<FleetLicenseDocument>> addFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    addCalls += 1;
    return addResult;
  }

  @override
  Future<Result<FleetLicenseDocument>> replaceFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile replacement,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    return Success(_frontDocument);
  }

  @override
  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    return removeResult;
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

  @override
  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  }) async {
    return Success(Uint8List.fromList([1]));
  }
}

final class _FakeBusinessDateProvider implements CompanyBusinessDateProvider {
  final UnexpectedFailure? failure;

  _FakeBusinessDateProvider({this.failure});

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    final currentFailure = failure;
    if (currentFailure != null) return FailureResult(currentFailure);
    return Success(BusinessDate(year: 2026, month: 9, day: 19));
  }
}
