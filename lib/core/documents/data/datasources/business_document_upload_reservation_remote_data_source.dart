import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/business_document_upload_rpc.dart';

/// Storage and PostgreSQL are not one transaction. This source owns only
/// the protected reservation RPCs; feature repositories own metadata commits.
abstract class BusinessDocumentUploadReservationRemoteDataSource {
  Future<void> reserve({
    required String companyId,
    required String operationId,
    required String bucketId,
    required String storageReference,
    String? replacesReference,
  });

  Future<void> releaseByReference({
    required String companyId,
    required String storageReference,
  });
}

final class SupabaseBusinessDocumentUploadReservationRemoteDataSource
    implements BusinessDocumentUploadReservationRemoteDataSource {
  final SupabaseClient client;

  const SupabaseBusinessDocumentUploadReservationRemoteDataSource(this.client);

  @override
  Future<void> reserve({
    required String companyId,
    required String operationId,
    required String bucketId,
    required String storageReference,
    String? replacesReference,
  }) async {
    final response = await client.rpc(
      BusinessDocumentUploadRpc.reserve,
      params: {
        BusinessDocumentUploadRpc.companyId: companyId,
        BusinessDocumentUploadRpc.operationId: operationId,
        BusinessDocumentUploadRpc.bucketId: bucketId,
        BusinessDocumentUploadRpc.storageReference: storageReference,
        BusinessDocumentUploadRpc.replacesReference: replacesReference,
      },
    );
    if (response is! Map ||
        response[BusinessDocumentUploadRpc.state] !=
            BusinessDocumentUploadRpc.reserved) {
      throw const FormatException('Invalid document reservation response.');
    }
  }

  @override
  Future<void> releaseByReference({
    required String companyId,
    required String storageReference,
  }) async {
    await client.rpc(
      BusinessDocumentUploadRpc.releaseByReference,
      params: {
        BusinessDocumentUploadRpc.companyId: companyId,
        BusinessDocumentUploadRpc.storageReference: storageReference,
      },
    );
  }
}
