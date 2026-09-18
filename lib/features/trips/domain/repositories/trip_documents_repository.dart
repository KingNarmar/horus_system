import 'dart:typed_data';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_document.dart';
import '../entities/trip_document_kind.dart';

abstract class TripDocumentsRepository {
  Future<Result<List<TripDocument>>> getActiveDocuments({
    required String companyId,
    required String tripId,
  });

  Future<Result<TripDocument>> upload({
    required String companyId,
    required String tripId,
    required TripDocumentKind kind,
    required BusinessDocumentFile document,
  });

  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required String tripId,
    required String documentId,
  });

  Future<Result<Uint8List>> download({
    required String companyId,
    required String tripId,
    required String documentId,
  });

  Future<Result<TripDocument>> replace({
    required String companyId,
    required String tripId,
    required String documentId,
    required BusinessDocumentFile document,
  });

  Future<Result<void>> remove({
    required String companyId,
    required String tripId,
    required String documentId,
  });
}
