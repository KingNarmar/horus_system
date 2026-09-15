import 'dart:typed_data';

import '../../../utils/result.dart';
import '../entities/business_document_access.dart';
import '../entities/business_document_file.dart';
import '../entities/business_document_location.dart';
import '../entities/business_document_reference.dart';

/// App-wide document boundary only.
///
/// Owning feature repositories remain responsible for persisting the returned
/// reference, enforcing narrower business permissions, and coordinating audit
/// after successful business mutations.
abstract class BusinessDocumentRepository {
  Future<Result<BusinessDocumentReference>> upload({
    required BusinessDocumentLocation location,
    required BusinessDocumentFile file,
  });

  Future<Result<Uint8List>> download({
    required String companyId,
    required BusinessDocumentReference reference,
  });

  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required String companyId,
    required BusinessDocumentReference reference,
  });

  Future<Result<void>> delete({
    required String companyId,
    required BusinessDocumentReference reference,
  });
}
