import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/failures/trip_document_failure_codes.dart';
import 'package:horus_system/features/trips/domain/repositories/trip_documents_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/trip_document_usecases.dart';

void main() {
  group('Trip document use cases', () {
    test('viewer can load active Trip documents', () async {
      final repository = _FakeTripDocumentsRepository()
        ..documents = [_document(TripDocumentKind.waybill)];
      final useCase = GetTripDocumentsUseCase(repository);

      final result = await useCase(
        const GetTripDocumentsParams(
          currentCompanyContext: _viewerContext,
          tripId: 'trip-1',
        ),
      );

      expect(result, isA<Success<List<TripDocument>>>());
      expect(result.dataOrNull, hasLength(1));
    });

    test('driver cannot view Trip documents', () async {
      final repository = _FakeTripDocumentsRepository();
      final useCase = GetTripDocumentsUseCase(repository);

      final result = await useCase(
        const GetTripDocumentsParams(
          currentCompanyContext: _driverContext,
          tripId: 'trip-1',
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        TripDocumentFailureCodes.permissionView,
      );
    });

    test('upload stops at ten active documents before persistence', () async {
      final repository = _FakeTripDocumentsRepository()
        ..documents = List.generate(
          10,
          (index) => _document(
            TripDocumentKind.other,
            id: 'document-$index',
          ),
        );
      final useCase = UploadTripDocumentUseCase(repository);

      final result = await useCase(
        UploadTripDocumentParams(
          currentCompanyContext: _operationsContext,
          tripId: 'trip-1',
          kind: TripDocumentKind.other,
          document: _file,
        ),
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        TripDocumentFailureCodes.conflictMaxActiveDocuments,
      );
      expect(repository.uploadCalls, 0);
    });

    test(
      'remove blocks the last qualifying evidence from documents received',
      () async {
        final waybill = _document(
          TripDocumentKind.waybill,
          id: 'waybill',
        );
        final repository = _FakeTripDocumentsRepository()
          ..documents = [waybill];
        final useCase = RemoveTripDocumentUseCase(repository);

        final result = await useCase(
          RemoveTripDocumentParams(
            currentCompanyContext: _operationsContext,
            trip: _trip(TripStatus.documentsReceived),
            document: waybill,
          ),
        );

        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull?.code,
          TripDocumentFailureCodes.conflictEvidenceRequired,
        );
        expect(repository.removeCalls, 0);
      },
    );

    test('remove allows non-required evidence before protected statuses', () async {
      final loadingOrder = _document(
        TripDocumentKind.loadingOrder,
        id: 'loading',
      );
      final repository = _FakeTripDocumentsRepository()
        ..documents = [loadingOrder];
      final useCase = RemoveTripDocumentUseCase(repository);

      final result = await useCase(
        RemoveTripDocumentParams(
          currentCompanyContext: _operationsContext,
          trip: _trip(TripStatus.delivered),
          document: loadingOrder,
        ),
      );

      expect(result, isA<Success<void>>());
      expect(repository.removeCalls, 1);
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

final _file = BusinessDocumentFile(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'evidence.pdf',
  mimeType: 'application/pdf',
);

TripEntity _trip(TripStatus status) {
  return TripEntity(
    id: 'trip-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    routeId: 'route-1',
    status: status,
  );
}

TripDocument _document(
  TripDocumentKind kind, {
  String id = 'document-1',
}) {
  return TripDocument(
    id: id,
    companyId: 'company-1',
    tripId: 'trip-1',
    kind: kind,
    originalFileName: 'evidence.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 3,
    uploadedAt: DateTime.utc(2026, 9, 18),
  );
}

final class _FakeTripDocumentsRepository implements TripDocumentsRepository {
  List<TripDocument> documents = const [];
  int uploadCalls = 0;
  int removeCalls = 0;

  @override
  Future<Result<List<TripDocument>>> getActiveDocuments({
    required String companyId,
    required String tripId,
  }) {
    return Future.value(Success(documents));
  }

  @override
  Future<Result<TripDocument>> upload({
    required String companyId,
    required String tripId,
    required TripDocumentKind kind,
    required BusinessDocumentFile document,
  }) {
    uploadCalls++;
    return Future.value(Success(_document(kind)));
  }

  @override
  Future<Result<void>> remove({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    removeCalls++;
    return Future.value(const Success<void>(null));
  }

  @override
  Future<Result<TripDocument>> replace({
    required String companyId,
    required String tripId,
    required String documentId,
    required BusinessDocumentFile document,
  }) {
    return Future.value(
      Success(_document(TripDocumentKind.other, id: 'replacement')),
    );
  }

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    return Future.value(
      const Success(BusinessDocumentAccess('https://example.test')),
    );
  }

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required String tripId,
    required String documentId,
  }) {
    return Future.value(Success(Uint8List.fromList([1])));
  }
}
