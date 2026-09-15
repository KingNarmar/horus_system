import 'package:horus_system/core/documents/data/repositories/business_document_storage_failure_mapper.dart';
import 'package:horus_system/core/documents/domain/failures/business_document_failure_codes.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  const mapper = BusinessDocumentStorageFailureMapper();

  group('BusinessDocumentStorageFailureMapper', () {
    test('maps permission failures without exposing backend text', () {
      final failure = mapper.fromStorage(
        const StorageException('secret access detail', statusCode: '403'),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, BusinessDocumentFailureCodes.permissionAccess);
      expect(failure.message, isNull);
    });

    test('maps not found and conflict failures', () {
      final notFound = mapper.fromStorage(
        const StorageException('missing object', statusCode: '404'),
      );
      final conflict = mapper.fromStorage(
        const StorageException('duplicate object', statusCode: '409'),
      );

      expect(notFound, isA<NotFoundFailure>());
      expect(notFound.code, BusinessDocumentFailureCodes.notFound);
      expect(conflict, isA<ConflictFailure>());
      expect(conflict.code, BusinessDocumentFailureCodes.conflictAlreadyExists);
    });

    test('maps storage validation failures to stable codes', () {
      final tooLarge = mapper.fromStorage(
        const StorageException('Payload is too large', statusCode: '413'),
      );
      final unsupported = mapper.fromStorage(
        const StorageException('Unsupported MIME type', statusCode: '415'),
      );

      expect(
        tooLarge.code,
        BusinessDocumentFailureCodes.validationFileTooLarge,
      );
      expect(
        unsupported.code,
        BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
    });

    test('sanitizes server and unexpected failures', () {
      final server = mapper.fromStorage(
        const StorageException('private provider detail', statusCode: '500'),
      );
      final unexpected = mapper.fromUnexpected(
        StateError('private implementation detail'),
      );

      expect(server, isA<ServerFailure>());
      expect(server.code, BusinessDocumentFailureCodes.storageError);
      expect(server.message, isNull);
      expect(unexpected, isA<UnexpectedFailure>());
      expect(unexpected.code, BusinessDocumentFailureCodes.unexpectedError);
      expect(unexpected.message, isNull);
    });
  });
}
