import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/data/utils/uuid_v4.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../../domain/entities/driver_image_urls.dart';
import '../../domain/entities/driver_write_data.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../datasources/driver_images_remote_data_source.dart';
import '../datasources/drivers_remote_data_source.dart';
import '../mappers/driver_mapper.dart';
import '../models/driver_model.dart';
import 'driver_change_detector.dart';
import 'driver_image_upload_coordinator.dart';
import 'driver_repository_audit_writer.dart';
import 'driver_repository_failure_mapper.dart';

class DriversRepositoryImpl implements DriversRepository {
  final DriversRemoteDataSource remoteDataSource;
  final DriverImagesRemoteDataSource imagesRemoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final DriverChangeDetector _changeDetector;
  final DriverRepositoryFailureMapper _failureMapper;

  const DriversRepositoryImpl({
    required this.remoteDataSource,
    required this.imagesRemoteDataSource,
    required this.createAuditLogUseCase,
  }) : _changeDetector = const DriverChangeDetector(),
       _failureMapper = const DriverRepositoryFailureMapper();

  DriverImageUploadCoordinator get _imageUploads {
    return DriverImageUploadCoordinator(imagesRemoteDataSource);
  }

  DriverRepositoryAuditWriter get _auditWriter {
    return DriverRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<Driver>>> getDrivers({required String companyId}) {
    return _guard(() async {
      final normalizedCompanyId = companyId.trim();
      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<List<Driver>>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        );
      }

      final models = await remoteDataSource.getDrivers(
        companyId: normalizedCompanyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<Driver>> addDriver({
    required DriverWriteData data,
    required String actorRole,
    DriverImageUploadSet? imageUploads,
  }) {
    return _guard(() async {
      final driverId = _driverIdForInsert();
      final uploadedPaths = <String>[];
      try {
        final dataWithImages = await _imageUploads.dataWithUploadedImages(
          driverId: driverId,
          data: data,
          imageUploads: imageUploads,
          uploadedPaths: uploadedPaths,
        );
        final model = await remoteDataSource.addDriverWithId(
          driverId: driverId,
          data: dataWithImages,
        );
        return _withAudit(
          model: model,
          actorRole: actorRole,
          action: AuditAction.created,
          description: 'driver_created',
        );
      } catch (_) {
        await _imageUploads.removeUploadedImages(paths: uploadedPaths);
        rethrow;
      }
    });
  }

  @override
  Future<Result<Driver>> updateDriver({
    required String driverId,
    required DriverWriteData data,
    required String actorRole,
    DriverImageUploadSet? imageUploads,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getDriverById(
        companyId: data.companyId,
        driverId: driverId,
      );
      final uploadedPaths = <String>[];
      try {
        final dataWithImages = await _imageUploads.dataWithUploadedImages(
          driverId: driverId,
          data: data,
          imageUploads: imageUploads,
          fallback: oldModel,
          uploadedPaths: uploadedPaths,
        );
        if (!_changeDetector.hasDriverChanges(oldModel, dataWithImages)) {
          return Success(oldModel.toEntity());
        }
        final model = await remoteDataSource.updateDriver(
          driverId: driverId,
          data: dataWithImages,
        );
        return _withAudit(
          model: model,
          actorRole: actorRole,
          action: AuditAction.updated,
          description: 'driver_updated',
          oldValues: oldModel.toAuditValues(),
        );
      } catch (_) {
        await _imageUploads.removeUploadedImages(paths: uploadedPaths);
        rethrow;
      }
    });
  }

  String _driverIdForInsert() => newUuidV4();

  @override
  Future<Result<Driver>> deactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      driverId: driverId,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      description: 'driver_deactivated',
      mutate: remoteDataSource.deactivateDriver,
    );
  }

  @override
  Future<Result<Driver>> reactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      driverId: driverId,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      description: 'driver_reactivated',
      mutate: remoteDataSource.reactivateDriver,
    );
  }

  @override
  Future<Result<DriverImageUrls>> getDriverImageUrls({required Driver driver}) {
    return _guard(() async {
      return Success(
        DriverImageUrls(
          profileImageUrl: await _imageUploads.signedUrl(
            driver.profileImagePath,
          ),
          licenseImageUrl: await _imageUploads.signedUrl(
            driver.licenseImagePath,
          ),
          licenseBackImageUrl: await _imageUploads.signedUrl(
            driver.licenseBackImagePath,
          ),
          nationalIdImageUrl: await _imageUploads.signedUrl(
            driver.nationalIdImagePath,
          ),
          nationalIdBackImageUrl: await _imageUploads.signedUrl(
            driver.nationalIdBackImagePath,
          ),
        ),
      );
    });
  }

  Future<Result<Driver>> _changeStatus({
    required String companyId,
    required String driverId,
    required String actorRole,
    required AuditAction action,
    required String description,
    required Future<DriverModel> Function({
      required String companyId,
      required String driverId,
    })
    mutate,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getDriverById(
        companyId: companyId,
        driverId: driverId,
      );
      final model = await mutate(companyId: companyId, driverId: driverId);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: action,
        description: description,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  Future<Result<Driver>> _withAudit({
    required DriverModel model,
    required String actorRole,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
  }) async {
    final auditFailure = await _auditWriter.writeDriverAudit(
      companyId: model.companyId,
      actorRole: actorRole,
      entityId: model.id,
      entityDisplayName: model.fullName,
      action: action,
      description: description,
      oldValues: oldValues,
      newValues: model.toAuditValues(),
    );

    if (auditFailure != null) return FailureResult(auditFailure);
    return Success(model.toEntity());
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } on StorageException catch (error) {
      return FailureResult(_failureMapper.fromStorage(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
