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
      final repository = _FakeRepository()..activeDocument = _document;
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.load(
        currentCompanyContext: _operationsContext,
        target: _target,
      );

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(state.document?.id, _document.id);
      expect(state.canManage, isTrue);
      expect(state.isMutating, isFalse);
      expect(state.failure, isNull);
    });

    test('viewer load remains read-only', () async {
      final repository = _FakeRepository()..activeDocument = _document;
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.load(
        currentCompanyContext: _viewerContext,
        target: _target,
      );

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(state.document?.id, _document.id);
      expect(state.canManage, isFalse);
    });

    test('successful remove clears only document state', () async {
      final repository = _FakeRepository()..activeDocument = _document;
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.load(
        currentCompanyContext: _operationsContext,
        target: _target,
      );
      final changed = await cubit.remove(_document);

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(changed, isTrue);
      expect(state.document, isNull);
      expect(state.failure, isNull);
      expect(repository.removeCalls, 1);
    });

    test('failed remove preserves document and exposes typed failure', () async {
      const failure = ServerFailure(code: 'fleet_license_document_server_error');
      final repository = _FakeRepository()
        ..activeDocument = _document
        ..removeResult = const FailureResult<void>(failure);
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.load(
        currentCompanyContext: _operationsContext,
        target: _target,
      );
      final changed = await cubit.remove(_document);

      final state = cubit.state as FleetLicenseDocumentsLoaded;
      expect(changed, isFalse);
      expect(state.document?.id, _document.id);
      expect(state.failure, same(failure));
      expect(state.isMutating, isFalse);
    });
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

final _document = FleetLicenseDocument(
  id: 'document-1',
  companyId: 'company-1',
  assetType: FleetAssetType.tractorHead,
  assetId: 'tractor-1',
  originalFileName: 'license.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 3,
  uploadedAt: DateTime.utc(2026, 9, 18),
);

FleetLicenseDocumentsCubit _createCubit(
  FleetLicenseDocumentsRepository repository,
) {
  return FleetLicenseDocumentsCubit(
    getDocumentUseCase: GetFleetLicenseDocumentUseCase(repository),
    uploadDocumentUseCase: UploadFleetLicenseDocumentUseCase(repository),
    getDocumentAccessUseCase:
        GetFleetLicenseDocumentAccessUseCase(repository),
    downloadDocumentUseCase: DownloadFleetLicenseDocumentUseCase(repository),
    replaceDocumentUseCase: ReplaceFleetLicenseDocumentUseCase(repository),
    removeDocumentUseCase: RemoveFleetLicenseDocumentUseCase(repository),
    canManageFleetUseCase: const CanManageFleetUseCase(),
  );
}

final class _FakeRepository implements FleetLicenseDocumentsRepository {
  FleetLicenseDocument? activeDocument;
  Result<void> removeResult = const Success<void>(null);
  int removeCalls = 0;

  @override
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  }) async {
    return Success(activeDocument);
  }

  @override
  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) async {
    removeCalls++;
    return removeResult;
  }

  @override
  Future<Result<FleetLicenseDocument>> upload({
    required FleetLicenseDocumentTarget target,
    required BusinessDocumentFile document,
    BusinessDate? newLicenseExpiryDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<FleetLicenseDocument>> replace({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required BusinessDocumentFile document,
    BusinessDate? newLicenseExpiryDate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) {
    return Future.value(
      const Success(BusinessDocumentAccess('https://example.test/license')),
    );
  }

  @override
  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  }) {
    return Future.value(Success(Uint8List.fromList([1])));
  }
}
