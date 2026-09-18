import 'dart:typed_data';

import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
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
import 'package:horus_system/features/fleet/domain/failures/fleet_license_document_failure_codes.dart';
import 'package:horus_system/features/fleet/domain/repositories/fleet_license_documents_repository.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_license_document_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('Fleet license document use cases', () {
    test('viewer can load active license document', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final useCase = GetFleetLicenseDocumentUseCase(repository);

      final result = await useCase(
        const GetFleetLicenseDocumentParams(
          currentCompanyContext: _viewerContext,
          target: _tractorTarget,
        ),
      );

      expect(result, isA<Success<FleetLicenseDocument?>>());
      expect(result.dataOrNull?.frontFile?.id, _frontFile.id);
      expect(repository.getCalls, 1);
    });

    test('driver cannot view Fleet license documents', () async {
      final repository = _FakeRepository();
      final useCase = GetFleetLicenseDocumentUseCase(repository);

      final result = await useCase(
        const GetFleetLicenseDocumentParams(
          currentCompanyContext: _driverContext,
          target: _tractorTarget,
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FleetLicenseDocumentFailureCodes.permissionView,
      );
      expect(repository.getCalls, 0);
    });

    test('cross-company upload is denied before repository call', () async {
      final repository = _FakeRepository();
      final useCase = UploadFleetLicenseDocumentFileUseCase(repository);

      final result = await useCase(
        UploadFleetLicenseDocumentFileParams(
          currentCompanyContext: _operationsContext,
          target: const FleetLicenseDocumentTarget(
            companyId: 'company-2',
            assetType: FleetAssetType.tractorHead,
            assetId: 'tractor-1',
          ),
          side: FleetLicenseDocumentFileSide.front,
          file: _file,
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(repository.createCalls, 0);
      expect(repository.addCalls, 0);
    });

    test('first side creates the license aggregate', () async {
      final repository = _FakeRepository();
      final useCase = UploadFleetLicenseDocumentFileUseCase(repository);

      final result = await useCase(
        UploadFleetLicenseDocumentFileParams(
          currentCompanyContext: _operationsContext,
          target: _tractorTarget,
          side: FleetLicenseDocumentFileSide.front,
          file: _file,
        ),
      );

      expect(result, isA<Success<FleetLicenseDocument>>());
      expect(repository.createCalls, 1);
      expect(repository.addCalls, 0);
      expect(repository.lastSide, FleetLicenseDocumentFileSide.front);
    });

    test('missing back side is added to the same active document', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final useCase = UploadFleetLicenseDocumentFileUseCase(repository);

      final result = await useCase(
        UploadFleetLicenseDocumentFileParams(
          currentCompanyContext: _operationsContext,
          target: _tractorTarget,
          side: FleetLicenseDocumentFileSide.back,
          file: _file,
        ),
      );

      expect(result, isA<Success<FleetLicenseDocument>>());
      expect(repository.createCalls, 0);
      expect(repository.addCalls, 1);
      expect(repository.lastDocumentId, _frontDocument.id);
      expect(repository.lastSide, FleetLicenseDocumentFileSide.back);
    });

    test('duplicate active side is rejected before persistence', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final useCase = UploadFleetLicenseDocumentFileUseCase(repository);

      final result = await useCase(
        UploadFleetLicenseDocumentFileParams(
          currentCompanyContext: _operationsContext,
          target: _tractorTarget,
          side: FleetLicenseDocumentFileSide.front,
          file: _file,
        ),
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        FleetLicenseDocumentFailureCodes.conflictFileSide,
      );
      expect(repository.addCalls, 0);
    });

    test('replace forwards side and exact optional Business Date', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final useCase = ReplaceFleetLicenseDocumentFileUseCase(repository);
      final newExpiry = BusinessDate(year: 2028, month: 2, day: 29);

      final result = await useCase(
        ReplaceFleetLicenseDocumentFileParams(
          currentCompanyContext: _operationsContext,
          target: _tractorTarget,
          document: _frontDocument,
          file: _frontFile,
          replacement: _file,
          newLicenseExpiryDate: newExpiry,
        ),
      );

      expect(result, isA<Success<FleetLicenseDocument>>());
      expect(repository.replaceCalls, 1);
      expect(repository.lastSide, FleetLicenseDocumentFileSide.front);
      expect(repository.lastExpiryDate, newExpiry);
    });

    test('remove does not carry or clear license expiry state', () async {
      final repository = _FakeRepository()..activeDocument = _frontDocument;
      final useCase = RemoveFleetLicenseDocumentUseCase(repository);

      final result = await useCase(
        const FleetLicenseDocumentActionParams(
          currentCompanyContext: _operationsContext,
          target: _tractorTarget,
          document: _frontDocument,
        ),
      );

      expect(result, isA<Success<void>>());
      expect(repository.removeCalls, 1);
      expect(repository.lastExpiryDate, isNull);
    });
  });
}

const _company = Company(id: 'company-1', name: 'Company');
const _viewerContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.viewer,
);
const _driverContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.driver,
);
const _operationsContext = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.operations,
);
const _tractorTarget = FleetLicenseDocumentTarget(
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
);
const _frontFile = FleetLicenseDocumentFile(
  id: 'front-file',
  companyId: 'company-1',
  licenseDocumentId: 'document-1',
  side: FleetLicenseDocumentFileSide.front,
  originalFileName: 'front.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 3,
  uploadedAt: _uploadedAt,
);
const _frontDocument = FleetLicenseDocument(
  id: 'document-1',
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
  files: [_frontFile],
  uploadedAt: _uploadedAt,
);
const _uploadedAt = DateTime.utc(2026, 9, 18);

final _file = BusinessDocumentFile(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'license.pdf',
  mimeType: 'application/pdf',
);

final class _FakeRepository implements FleetLicenseDocumentsRepository {
  FleetLicenseDocument? activeDocument;
  int getCalls = 0;
  int createCalls = 0;
  int addCalls = 0;
  int replaceCalls = 0;
  int removeCalls = 0;
  String? lastDocumentId;
  FleetLicenseDocumentFileSide? lastSide;
  BusinessDate? lastExpiryDate;

  @override
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) async {
    getCalls++;
    return Success(activeDocument);
  }

  @override
  Future<Result<FleetLicenseDocument>> createWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    createCalls++;
    lastSide = side;
    lastExpiryDate = newLicenseExpiryDate;
    return const Success(_frontDocument);
  }

  @override
  Future<Result<FleetLicenseDocument>> addFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  }) async {
    addCalls++;
    lastDocumentId = documentId;
    lastSide = side;
    lastExpiryDate = newLicenseExpiryDate;
    return const Success(_frontDocument);
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
    replaceCalls++;
    lastDocumentId = documentId;
    lastSide = side;
    lastExpiryDate = newLicenseExpiryDate;
    return const Success(_frontDocument);
  }

  @override
  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    removeCalls++;
    return const Success<void>(null);
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
