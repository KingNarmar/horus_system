import '../../domain/entities/driver_image_file.dart';
import '../../domain/entities/driver_write_data.dart';
import '../constants/driver_storage_constants.dart';
import '../datasources/driver_images_remote_data_source.dart';
import '../models/driver_model.dart';

final class DriverImageUploadCoordinator {
  final DriverImagesRemoteDataSource imagesRemoteDataSource;

  const DriverImageUploadCoordinator(this.imagesRemoteDataSource);

  Future<DriverWriteData> dataWithUploadedImages({
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

  Future<void> removeUploadedImages({required List<String> paths}) {
    return imagesRemoteDataSource.removeImages(paths: paths);
  }

  Future<String?> signedUrl(String? path) {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) {
      return Future.value();
    }
    return imagesRemoteDataSource.createSignedUrl(path: normalized);
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
}
