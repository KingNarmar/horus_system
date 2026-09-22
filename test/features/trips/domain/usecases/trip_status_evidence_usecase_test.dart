import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status_history.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:horus_system/features/trips/domain/failures/trip_failure_codes.dart';
import 'package:horus_system/features/trips/domain/repositories/trip_documents_repository.dart';
import 'package:horus_system/features/trips/domain/repositories/trips_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/trip_status_usecases.dart';
import 'package:horus_system/features/trips/domain/usecases/trip_usecase_params.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';

void main() {
  group('UpdateTripStatusUseCase evidence rule', () {
    test(
      'blocks delivered to documents received without qualifying evidence',
      () async {
        final tripsRepository = _FakeTripsRepository();
        final documentsRepository = _FakeDocumentsRepository();
        final useCase = UpdateTripStatusUseCase(
          tripsRepository,
          documentsRepository,
        );

        final result = await useCase(
          const UpdateTripStatusParams(
            currentCompanyContext: _context,
            id: 'trip-1',
            newStatus: TripStatus.documentsReceived,
          ),
        );

        expect(result.failureOrNull, isA<ConflictFailure>());
        expect(
          result.failureOrNull?.code,
          TripFailureCodes.conflictStatusEvidenceRequired,
        );
        expect(tripsRepository.statusUpdateCalls, 0);
      },
    );

    test(
      'allows delivered to documents received with an active waybill',
      () async {
        final tripsRepository = _FakeTripsRepository();
        final documentsRepository = _FakeDocumentsRepository()
          ..documents = [_waybill];
        final useCase = UpdateTripStatusUseCase(
          tripsRepository,
          documentsRepository,
        );

        final result = await useCase(
          const UpdateTripStatusParams(
            currentCompanyContext: _context,
            id: 'trip-1',
            newStatus: TripStatus.documentsReceived,
          ),
        );

        expect(result, isA<Success<TripEntity>>());
        expect(tripsRepository.statusUpdateCalls, 1);
        expect(result.dataOrNull?.status, TripStatus.documentsReceived);
      },
    );
  });
}

const _context = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Company'),
  role: CompanyRole.operations,
);

final _trip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.delivered,
);

final _waybill = TripDocument(
  id: 'document-1',
  companyId: 'company-1',
  tripId: 'trip-1',
  kind: TripDocumentKind.waybill,
  originalFileName: 'waybill.pdf',
  mimeType: 'application/pdf',
  sizeBytes: 10,
  uploadedAt: DateTime.utc(2026, 9, 18),
);

final class _FakeTripsRepository implements TripsRepository {
  int statusUpdateCalls = 0;

  @override
  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return Future.value(Success(_trip));
  }

  @override
  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required CurrencyConfiguration? financialConfiguration,
    String? notes,
  }) {
    statusUpdateCalls++;
    return Future.value(
      Success(
        TripEntity(
          id: _trip.id,
          companyId: _trip.companyId,
          tripNumber: _trip.tripNumber,
          customerId: _trip.customerId,
          routeId: _trip.routeId,
          status: newStatus,
        ),
      ),
    );
  }

  @override
  Future<Result<List<TripEntity>>> getTrips({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<TripFormLookups>> getTripFormLookups({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<TripStatusHistory>>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) => throw UnimplementedError();

  @override
  Future<Result<bool>> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) => throw UnimplementedError();
}

final class _FakeDocumentsRepository implements TripDocumentsRepository {
  List<TripDocument> documents = const [];

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
  }) => throw UnimplementedError();

  @override
  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required String tripId,
    required String documentId,
  }) => throw UnimplementedError();

  @override
  Future<Result<Uint8List>> download({
    required String companyId,
    required String tripId,
    required String documentId,
  }) => throw UnimplementedError();

  @override
  Future<Result<TripDocument>> replace({
    required String companyId,
    required String tripId,
    required String documentId,
    required BusinessDocumentFile document,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> remove({
    required String companyId,
    required String tripId,
    required String documentId,
  }) => throw UnimplementedError();
}
