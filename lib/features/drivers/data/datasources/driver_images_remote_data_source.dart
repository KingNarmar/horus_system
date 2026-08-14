import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/driver_image_file.dart';
import '../constants/driver_storage_constants.dart';

abstract class DriverImagesRemoteDataSource {
  Future<String> uploadDriverImage({
    required String companyId,
    required String driverId,
    required String folder,
    required DriverImageFile image,
  });

  Future<String> createSignedUrl({required String path});

  Future<void> removeImages({required List<String> paths});
}

class SupabaseDriverImagesRemoteDataSource
    implements DriverImagesRemoteDataSource {
  final SupabaseClient client;

  const SupabaseDriverImagesRemoteDataSource(this.client);

  @override
  Future<String> uploadDriverImage({
    required String companyId,
    required String driverId,
    required String folder,
    required DriverImageFile image,
  }) async {
    final path = _buildPath(
      companyId: companyId,
      driverId: driverId,
      folder: folder,
      fileName: image.fileName,
    );

    await client.storage
        .from(DriverStorageConstants.documentsBucket)
        .uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            contentType: image.mimeType ?? _contentTypeFor(image.fileName),
            upsert: true,
          ),
        );

    return path;
  }

  @override
  Future<String> createSignedUrl({required String path}) {
    return client.storage
        .from(DriverStorageConstants.documentsBucket)
        .createSignedUrl(
          path,
          DriverStorageConstants.signedUrlExpiresInSeconds,
        );
  }

  @override
  Future<void> removeImages({required List<String> paths}) async {
    if (paths.isEmpty) return;
    await client.storage
        .from(DriverStorageConstants.documentsBucket)
        .remove(paths);
  }

  String _buildPath({
    required String companyId,
    required String driverId,
    required String folder,
    required String fileName,
  }) {
    final extension = _extensionOf(fileName);
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'companies/$companyId/drivers/$driverId/$folder/$timestamp$extension';
  }

  String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  String _contentTypeFor(String fileName) {
    final extension = _extensionOf(fileName);
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      '.heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}
