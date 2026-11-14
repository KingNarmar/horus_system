import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/utils/uuid_v4.dart';
import '../../../../core/documents/data/datasources/business_document_upload_reservation_remote_data_source.dart';

import '../../domain/entities/driver_image_file.dart';
import '../constants/driver_storage_constants.dart';

abstract class DriverImagesRemoteDataSource {
  Future<String> uploadDriverImage({
    required String companyId,
    required String driverId,
    required String folder,
    required DriverImageFile image,
    String? replacesReference,
  });

  Future<String> createSignedUrl({required String path});

  Future<void> removeImages({
    required String companyId,
    required List<String> paths,
  });
}

class SupabaseDriverImagesRemoteDataSource
    implements DriverImagesRemoteDataSource {
  final SupabaseClient client;
  final BusinessDocumentUploadReservationRemoteDataSource reservationDataSource;

  const SupabaseDriverImagesRemoteDataSource(
    this.client, {
    required this.reservationDataSource,
  });

  @override
  Future<String> uploadDriverImage({
    required String companyId,
    required String driverId,
    required String folder,
    required DriverImageFile image,
    String? replacesReference,
  }) async {
    final path = _buildPath(
      companyId: companyId,
      driverId: driverId,
      folder: folder,
      fileName: image.fileName,
    );

    final requiresReservation = folder != DriverStorageConstants.profileFolder;
    if (requiresReservation) {
      await reservationDataSource.reserve(
        companyId: companyId,
        operationId: newUuidV4(),
        bucketId: DriverStorageConstants.documentsBucket,
        storageReference: path,
        replacesReference: replacesReference,
      );
    }

    try {
      await client.storage
          .from(DriverStorageConstants.documentsBucket)
          .uploadBinary(
            path,
            image.bytes,
            fileOptions: FileOptions(
              contentType: image.mimeType ?? _contentTypeFor(image.fileName),
              upsert: false,
            ),
          );
    } catch (_) {
      var cleanupFailed = false;
      try {
        await client.storage
            .from(DriverStorageConstants.documentsBucket)
            .remove([path]);
      } catch (_) {
        cleanupFailed = true;
      }
      if (requiresReservation) {
        try {
          await reservationDataSource.releaseByReference(
            companyId: companyId,
            storageReference: path,
          );
        } catch (_) {
          cleanupFailed = true;
        }
      }
      if (cleanupFailed) throw const DriverDocumentCleanupPendingException();
      rethrow;
    }
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
  Future<void> removeImages({
    required String companyId,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;

    var cleanupFailed = false;
    try {
      await client.storage
          .from(DriverStorageConstants.documentsBucket)
          .remove(paths);
    } catch (_) {
      cleanupFailed = true;
    }

    for (final path in paths) {
      if (path.split('/')[4] == DriverStorageConstants.profileFolder) {
        continue;
      }
      try {
        await reservationDataSource.releaseByReference(
          companyId: companyId,
          storageReference: path,
        );
      } catch (_) {
        cleanupFailed = true;
      }
    }
    if (cleanupFailed) throw const DriverDocumentCleanupPendingException();
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

/// A server-side cleanup is still needed. Never silently discard a failed
/// compensation while a private object might remain in Storage.
final class DriverDocumentCleanupPendingException implements Exception {
  const DriverDocumentCleanupPendingException();
}
