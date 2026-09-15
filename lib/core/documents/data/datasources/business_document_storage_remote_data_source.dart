import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/business_document_storage_constants.dart';

abstract class BusinessDocumentStorageRemoteDataSource {
  Future<void> upload({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
  });

  Future<Uint8List> download({required String objectKey});

  Future<String> createSignedUrl({required String objectKey});

  Future<void> delete({required String objectKey});
}

final class SupabaseBusinessDocumentStorageRemoteDataSource
    implements BusinessDocumentStorageRemoteDataSource {
  final SupabaseClient client;

  const SupabaseBusinessDocumentStorageRemoteDataSource(this.client);

  @override
  Future<void> upload({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await client.storage
        .from(BusinessDocumentStorageConstants.bucket)
        .uploadBinary(
          objectKey,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

  @override
  Future<Uint8List> download({required String objectKey}) {
    return client.storage
        .from(BusinessDocumentStorageConstants.bucket)
        .download(objectKey);
  }

  @override
  Future<String> createSignedUrl({required String objectKey}) {
    return client.storage
        .from(BusinessDocumentStorageConstants.bucket)
        .createSignedUrl(
          objectKey,
          BusinessDocumentStorageConstants.signedUrlExpiresInSeconds,
        );
  }

  @override
  Future<void> delete({required String objectKey}) async {
    await client.storage.from(BusinessDocumentStorageConstants.bucket).remove([
      objectKey,
    ]);
  }
}
