import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/data/utils/uuid_v4.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
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
import 'driver_repository_failure_mapper.dart';

class DriversRepositoryImpl implements DriversRepository {
  final DriversRemoteDataSource remoteDataSource;
  final DriverImagesRemoteDataSource imagesRemoteDataSource;
  final DriverChangeDetector _changeDetector;
  final DriverRepositoryFailureMapper _failureMapper;

  const DriversRepositoryImpl({
    required this.remoteDataSource,
    required this.imagesRemoteDataSource,
  }) : _changeDetector = const DriverChangeDetector(),
       _failureMapper = const DriverRepositoryFailureMapper();

  DriverImageUploadCoordinator get _imageUploads {
    return DriverImageUploadCoordinator(imagesRemoteDataSource);
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
        return Success(model.toEntity());
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
        return Success(model.toEntity());
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
    required Future<DriverModel> Function({
      required String companyId,
      required String driverId,
    })
    mutate,
  }) {
    return _guard(() async {
      final model = await mutate(companyId: companyId, driverId: driverId);
      return Success(model.toEntity());
    });
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
