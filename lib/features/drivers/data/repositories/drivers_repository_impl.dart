import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, StorageException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/data/utils/uuid_v4.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../../domain/entities/driver_image_urls.dart';
import '../../domain/entities/driver_write_data.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../constants/driver_storage_constants.dart';
import '../datasources/driver_images_remote_data_source.dart';
import '../datasources/drivers_remote_data_source.dart';
import '../mappers/driver_mapper.dart';
import '../models/driver_model.dart';

class DriversRepositoryImpl implements DriversRepository {
  final DriversRemoteDataSource remoteDataSource;
  final DriverImagesRemoteDataSource imagesRemoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const DriversRepositoryImpl({
    required this.remoteDataSource,
    required this.imagesRemoteDataSource,
    required this.createAuditLogUseCase,
  });

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
        final dataWithImages = await _dataWithUploadedImages(
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
        await imagesRemoteDataSource.removeImages(paths: uploadedPaths);
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
        final dataWithImages = await _dataWithUploadedImages(
          driverId: driverId,
          data: data,
          imageUploads: imageUploads,
          fallback: oldModel,
          uploadedPaths: uploadedPaths,
        );
        if (!_hasDriverChanges(oldModel, dataWithImages)) {
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
        await imagesRemoteDataSource.removeImages(paths: uploadedPaths);
        rethrow;
      }
    });
  }

  String _driverIdForInsert() => newUuidV4();

  Future<DriverWriteData> _dataWithUploadedImages({
    required String driverId,
    required DriverWriteData data,
    required List<String> uploadedPaths,
    DriverImageUploadSet? imageUploads,
    DriverModel? fallback,
  }) async {
    if (imageUploads == null || !imageUploads.hasAny) {
      return _copyWithImagePaths(
        data,
        profileImagePath: data.profileImagePath ?? fallback?.profileImagePath,
        licenseImagePath: data.licenseImagePath ?? fallback?.licenseImagePath,
        licenseBackImagePath:
            data.licenseBackImagePath ?? fallback?.licenseBackImagePath,
        nationalIdImagePath:
            data.nationalIdImagePath ?? fallback?.nationalIdImagePath,
        nationalIdBackImagePath:
            data.nationalIdBackImagePath ?? fallback?.nationalIdBackImagePath,
      );
    }

    final profileImagePath = await _uploadOptionalImage(
      companyId: data.companyId,
      driverId: driverId,
      folder: DriverStorageConstants.profileFolder,
      image: imageUploads.profileImage,
      fallbackPath: fallback?.profileImagePath,
      uploadedPaths: uploadedPaths,
    );
    final licenseImagePath = await _uploadOptionalImage(
      companyId: data.companyId,
      driverId: driverId,
      folder: DriverStorageConstants.licenseFrontFolder,
      image: imageUploads.licenseFrontImage,
      fallbackPath: fallback?.licenseImagePath,
      uploadedPaths: uploadedPaths,
    );
    final licenseBackImagePath = await _uploadOptionalImage(
      companyId: data.companyId,
      driverId: driverId,
      folder: DriverStorageConstants.licenseBackFolder,
      image: imageUploads.licenseBackImage,
      fallbackPath: fallback?.licenseBackImagePath,
      uploadedPaths: uploadedPaths,
    );
    final nationalIdImagePath = await _uploadOptionalImage(
      companyId: data.companyId,
      driverId: driverId,
      folder: DriverStorageConstants.nationalIdFrontFolder,
      image: imageUploads.nationalIdFrontImage,
      fallbackPath: fallback?.nationalIdImagePath,
      uploadedPaths: uploadedPaths,
    );
    final nationalIdBackImagePath = await _uploadOptionalImage(
      companyId: data.companyId,
      driverId: driverId,
      folder: DriverStorageConstants.nationalIdBackFolder,
      image: imageUploads.nationalIdBackImage,
      fallbackPath: fallback?.nationalIdBackImagePath,
      uploadedPaths: uploadedPaths,
    );

    return _copyWithImagePaths(
      data,
      profileImagePath: profileImagePath,
      licenseImagePath: licenseImagePath,
      licenseBackImagePath: licenseBackImagePath,
      nationalIdImagePath: nationalIdImagePath,
      nationalIdBackImagePath: nationalIdBackImagePath,
    );
  }

  Future<String?> _uploadOptionalImage({
    required String companyId,
    required String driverId,
    required String folder,
    required DriverImageFile? image,
    required String? fallbackPath,
    required List<String> uploadedPaths,
  }) async {
    if (image == null) return fallbackPath;
    final path = await imagesRemoteDataSource.uploadDriverImage(
      companyId: companyId,
      driverId: driverId,
      folder: folder,
      image: image,
    );
    uploadedPaths.add(path);
    return path;
  }

  DriverWriteData _copyWithImagePaths(
    DriverWriteData data, {
    String? profileImagePath,
    String? licenseImagePath,
    String? licenseBackImagePath,
    String? nationalIdImagePath,
    String? nationalIdBackImagePath,
  }) {
    return DriverWriteData(
      companyId: data.companyId,
      fullName: data.fullName,
      phone: data.phone,
      nationalId: data.nationalId,
      licenseNumber: data.licenseNumber,
      licenseExpiryDate: data.licenseExpiryDate,
      profileImagePath: profileImagePath,
      licenseImagePath: licenseImagePath,
      licenseBackImagePath: licenseBackImagePath,
      nationalIdImagePath: nationalIdImagePath,
      nationalIdBackImagePath: nationalIdBackImagePath,
      notes: data.notes,
    );
  }

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
          profileImageUrl: await _signedUrl(driver.profileImagePath),
          licenseImageUrl: await _signedUrl(driver.licenseImagePath),
          licenseBackImageUrl: await _signedUrl(driver.licenseBackImagePath),
          nationalIdImageUrl: await _signedUrl(driver.nationalIdImagePath),
          nationalIdBackImageUrl: await _signedUrl(
            driver.nationalIdBackImagePath,
          ),
        ),
      );
    });
  }

  Future<String?> _signedUrl(String? path) {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) {
      return Future.value();
    }
    return imagesRemoteDataSource.createSignedUrl(path: normalized);
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
    final auditFailure = await _writeDriverAudit(
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

  Future<Failure?> _writeDriverAudit({
    required String companyId,
    required String actorRole,
    required String entityId,
    required String entityDisplayName,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? newValues,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: entityId,
          entityDisplayName: entityDisplayName,
          action: action,
          description: description,
          oldValues: oldValues,
          newValues: newValues,
        ),
      ),
    );
    return result.failureOrNull;
  }

  bool _hasDriverChanges(DriverModel oldModel, DriverWriteData data) {
    return _textChanged(oldModel.fullName, data.fullName) ||
        _textChanged(oldModel.phone, data.phone) ||
        _textChanged(oldModel.nationalId, data.nationalId) ||
        _textChanged(oldModel.licenseNumber, data.licenseNumber) ||
        _dateChanged(oldModel.licenseExpiryDate, data.licenseExpiryDate) ||
        _textChanged(oldModel.profileImagePath, data.profileImagePath) ||
        _textChanged(oldModel.licenseImagePath, data.licenseImagePath) ||
        _textChanged(
          oldModel.licenseBackImagePath,
          data.licenseBackImagePath,
        ) ||
        _textChanged(oldModel.nationalIdImagePath, data.nationalIdImagePath) ||
        _textChanged(
          oldModel.nationalIdBackImagePath,
          data.nationalIdBackImagePath,
        ) ||
        _textChanged(oldModel.notes, data.notes);
  }

  bool _textChanged(String? oldValue, String? newValue) {
    return _normalizeText(oldValue) != _normalizeText(newValue);
  }

  String? _normalizeText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool _dateChanged(DateTime? oldValue, DateTime? newValue) {
    return _dateOnly(oldValue) != _dateOnly(newValue);
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } on StorageException catch (error) {
      return FailureResult(_storageFailure(error));
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  Failure _storageFailure(StorageException error) {
    final message = error.message.toLowerCase();
    final statusCode = error.statusCode;
    if (statusCode == '413' || message.contains('too large')) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTooLarge,
        message: 'Driver image file is too large.',
      );
    }
    if (statusCode == '415' ||
        message.contains('mime') ||
        message.contains('type')) {
      return const ValidationFailure(
        code: FailureCodes.validationDriverImageTypeUnsupported,
        message: 'Driver image file type is not supported.',
      );
    }
    return const ServerFailure(code: FailureCodes.serverError);
  }
}
