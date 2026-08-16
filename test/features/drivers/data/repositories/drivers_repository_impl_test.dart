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
import 'package:horus_system/features/drivers/data/repositories/drivers_repository_impl.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_file.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('DriversRepositoryImpl', () {
    test(
      'does not persist or audit when update has no meaningful changes',
      () async {
        final remoteDataSource = _FakeDriversRemoteDataSource(_driverModel);
        final auditRepository = _FakeAuditLogRepository();
        final repository = DriversRepositoryImpl(
          remoteDataSource: remoteDataSource,
          imagesRemoteDataSource: _FakeDriverImagesRemoteDataSource(),
          createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
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
  int updateCalls = 0;

  _FakeDriversRemoteDataSource(this.model);

  @override
  Future<List<DriverModel>> getDrivers({required String companyId}) async {
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
  }) {
    throw UnimplementedError();
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
  Future<String> createSignedUrl({required String path}) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeImages({required List<String> paths}) async {}
}

class _FakeAuditLogRepository implements AuditLogRepository {
  int createCalls = 0;

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    createCalls++;
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
