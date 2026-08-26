import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/drivers/data/datasources/driver_images_remote_data_source.dart';
import 'package:horus_system/features/drivers/data/datasources/drivers_remote_data_source.dart';
import 'package:horus_system/features/drivers/data/models/driver_model.dart';
import 'package:horus_system/features/drivers/data/mappers/driver_mapper.dart';
import 'package:horus_system/features/drivers/data/repositories/drivers_repository_impl.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_file.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('DriversRepositoryImpl', () {
    test('forwards company scope when loading drivers', () async {
      final remoteDataSource = _FakeDriversRemoteDataSource(_driverModel);
      final repository = _repository(remoteDataSource: remoteDataSource);

      final result = await repository.getDrivers(companyId: _companyId);

      expect(result.failureOrNull, isNull);
      expect(remoteDataSource.lastListCompanyId, _companyId);
    });

    test('sanitizes read PostgREST failures', () async {
      final repository = _repository(
        remoteDataSource: _FakeDriversRemoteDataSource(
          _driverModel,
          readError: _postgrestException,
        ),
      );

      final result = await repository.getDrivers(companyId: _companyId);

      _expectSanitizedServerFailure(result.failureOrNull);
    });

    test('keeps model mapping inside the sanitized boundary', () async {
      final repository = _repository(
        remoteDataSource: _FakeDriversRemoteDataSource(_ThrowingDriverModel()),
      );

      final result = await repository.getDrivers(companyId: _companyId);

      _expectSanitizedUnexpectedFailure(result.failureOrNull);
    });

    test('sanitizes unexpected mutation failures without auditing', () async {
      final operations = <String>[];
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource: _FakeDriversRemoteDataSource(
          _driverModel,
          addError: StateError('secret mutation detail'),
          operations: operations,
        ),
        auditRepository: auditRepository,
      );

      final result = await repository.addDriver(
        data: _writeData,
        actorRole: 'owner',
      );

      _expectSanitizedUnexpectedFailure(result.failureOrNull);
      expect(operations, ['add_driver']);
      expect(auditRepository.createCalls, 0);
    });

    test('adds a driver before writing its audit log', () async {
      final operations = <String>[];
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource: _FakeDriversRemoteDataSource(
          _driverModel,
          operations: operations,
        ),
        auditRepository: auditRepository,
      );

      final result = await repository.addDriver(
        data: _writeData,
        actorRole: 'owner',
      );

      expect(result.failureOrNull, isNull);
      expect(operations, ['add_driver', 'audit']);
    });

    test(
      'maps signed URL Storage failures through the typed boundary',
      () async {
        final repository = _repository(
          remoteDataSource: _FakeDriversRemoteDataSource(_driverModel),
          imagesRemoteDataSource: _FakeDriverImagesRemoteDataSource(
            signedUrlError: const StorageException(
              'Payload is too large',
              statusCode: '413',
            ),
          ),
        );

        final result = await repository.getDriverImageUrls(
          driver: _driverModel.toEntity(),
        );

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull?.code,
          FailureCodes.validationDriverImageTooLarge,
        );
      },
    );

    test(
      'does not persist or audit when update has no meaningful changes',
      () async {
        final remoteDataSource = _FakeDriversRemoteDataSource(_driverModel);
        final auditRepository = _FakeAuditLogRepository();
        final repository = _repository(
          remoteDataSource: remoteDataSource,
          auditRepository: auditRepository,
        );

        final result = await repository.updateDriver(
          driverId: _driverModel.id,
          actorRole: 'owner',
          data: DriverWriteData(
            companyId: _driverModel.companyId,
            fullName: _driverModel.fullName,
            phone: _driverModel.phone,
            nationalId: _driverModel.nationalId,
            licenseNumber: _driverModel.licenseNumber,
            licenseExpiryDate: _driverModel.licenseExpiryDate,
            profileImagePath: _driverModel.profileImagePath,
            licenseImagePath: _driverModel.licenseImagePath,
            licenseBackImagePath: _driverModel.licenseBackImagePath,
            nationalIdImagePath: _driverModel.nationalIdImagePath,
            nationalIdBackImagePath: _driverModel.nationalIdBackImagePath,
            notes: _driverModel.notes,
          ),
        );

        expect(result, isA<Success>());
        expect(remoteDataSource.updateCalls, 0);
        expect(auditRepository.createCalls, 0);
      },
    );
  });
}

const _companyId = 'company-1';

const _writeData = DriverWriteData(
  companyId: _companyId,
  fullName: 'Ashraf Samy',
  phone: '+201000000000',
  nationalId: '123456789',
  licenseNumber: 'L-123',
);

const _postgrestException = PostgrestException(
  message: 'secret backend message',
  code: 'XX999',
  details: 'private database details',
  hint: 'internal database hint',
);

DriversRepositoryImpl _repository({
  required DriversRemoteDataSource remoteDataSource,
  DriverImagesRemoteDataSource? imagesRemoteDataSource,
  _FakeAuditLogRepository? auditRepository,
}) {
  return DriversRepositoryImpl(
    remoteDataSource: remoteDataSource,
    imagesRemoteDataSource:
        imagesRemoteDataSource ?? _FakeDriverImagesRemoteDataSource(),
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditLogRepository(),
    ),
  );
}

void _expectSanitizedServerFailure(Object? failure) {
  expect(failure, isA<ServerFailure>());
  expect((failure as ServerFailure).code, FailureCodes.serverError);
  expect(failure.message, isNull);
}

void _expectSanitizedUnexpectedFailure(Object? failure) {
  expect(failure, isA<UnexpectedFailure>());
  expect((failure as UnexpectedFailure).code, FailureCodes.unexpectedError);
  expect(failure.message, isNull);
}

final _driverModel = DriverModel(
  id: 'driver-1',
  companyId: 'company-1',
  fullName: 'Ashraf Samy',
  phone: '+201000000000',
  nationalId: '123456789',
  licenseNumber: 'L-123',
  licenseExpiryDate: DateTime(2027, 1, 1),
  profileImagePath: 'profile-path',
  licenseImagePath: 'license-front-path',
  licenseBackImagePath: 'license-back-path',
  nationalIdImagePath: 'national-id-front-path',
  nationalIdBackImagePath: 'national-id-back-path',
  notes: 'notes',
);

class _FakeDriversRemoteDataSource implements DriversRemoteDataSource {
  final DriverModel model;
  final Object? readError;
  final Object? addError;
  final List<String>? operations;
  int updateCalls = 0;
  String? lastListCompanyId;

  _FakeDriversRemoteDataSource(
    this.model, {
    this.readError,
    this.addError,
    this.operations,
  });

  @override
  Future<List<DriverModel>> getDrivers({required String companyId}) async {
    lastListCompanyId = companyId;
    final error = readError;
    if (error != null) throw error;
    return [model];
  }

  @override
  Future<DriverModel> getDriverById({
    required String companyId,
    required String driverId,
  }) async {
    return model;
  }

  @override
  Future<DriverModel> addDriver({required DriverWriteData data}) {
    throw UnimplementedError();
  }

  @override
  Future<DriverModel> addDriverWithId({
    required String driverId,
    required DriverWriteData data,
  }) async {
    operations?.add('add_driver');
    final error = addError;
    if (error != null) throw error;
    return model;
  }

  @override
  Future<DriverModel> updateDriver({
    required String driverId,
    required DriverWriteData data,
  }) async {
    updateCalls++;
    return model;
  }

  @override
  Future<DriverModel> deactivateDriver({
    required String companyId,
    required String driverId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DriverModel> reactivateDriver({
    required String companyId,
    required String driverId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeDriverImagesRemoteDataSource
    implements DriverImagesRemoteDataSource {
  final Object? signedUrlError;

  const _FakeDriverImagesRemoteDataSource({this.signedUrlError});

  @override
  Future<String> uploadDriverImage({
    required String companyId,
    required String driverId,
    required String folder,
    required DriverImageFile image,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> createSignedUrl({required String path}) async {
    final error = signedUrlError;
    if (error != null) throw error;
    return 'https://example.com/$path';
  }

  @override
  Future<void> removeImages({required List<String> paths}) async {}
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final List<String>? operations;
  int createCalls = 0;

  _FakeAuditLogRepository({this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    createCalls++;
    operations?.add('audit');
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) {
    throw UnimplementedError();
  }
}

final class _ThrowingDriverModel extends DriverModel {
  _ThrowingDriverModel()
    : super(id: 'driver-1', companyId: _companyId, fullName: 'Driver');

  @override
  String get fullName => throw StateError('secret model mapping detail');
}
