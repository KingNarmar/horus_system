import 'dart:typed_data';

import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/documents/domain/failures/business_document_failure_codes.dart';
import 'package:horus_system/core/documents/domain/policies/business_document_file_policy.dart';
import 'package:test/test.dart';

void main() {
  const policy = BusinessDocumentFilePolicy();

  BusinessDocumentFile file({
    required String name,
    String? mimeType,
    int size = 4,
  }) {
    return BusinessDocumentFile(
      bytes: Uint8List(size),
      fileName: name,
      mimeType: mimeType,
    );
  }

  group('BusinessDocumentFilePolicy', () {
    test('accepts supported PDF and image files', () {
      expect(
        policy.validate(
          file(name: 'contract.pdf', mimeType: 'application/pdf'),
        ),
        isNull,
      );
      expect(
        policy.validate(file(name: 'evidence.JPG', mimeType: 'image/jpeg')),
        isNull,
      );
    });

    test('rejects empty files', () {
      final failure = policy.validate(file(name: 'contract.pdf', size: 0));

      expect(
        failure?.code,
        BusinessDocumentFailureCodes.validationFileEmpty,
      );
    });

    test('rejects files above the canonical size limit', () {
      final failure = policy.validate(
        file(
          name: 'contract.pdf',
          size: BusinessDocumentFilePolicy.maxFileBytes + 1,
        ),
      );

      expect(
        failure?.code,
        BusinessDocumentFailureCodes.validationFileTooLarge,
      );
    });

    test('rejects filenames without a supported extension', () {
      final missingExtension = policy.validate(file(name: 'contract'));
      final unsupported = policy.validate(file(name: 'contract.exe'));

      expect(
        missingExtension?.code,
        BusinessDocumentFailureCodes.validationFileNameInvalid,
      );
      expect(
        unsupported?.code,
        BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
    });

    test('rejects MIME type and extension mismatches', () {
      final failure = policy.validate(
        file(name: 'contract.pdf', mimeType: 'image/png'),
      );

      expect(
        failure?.code,
        BusinessDocumentFailureCodes.validationFileTypeUnsupported,
      );
    });

    test('infers content type when MIME type is absent', () {
      final document = file(name: 'license.webp');

      expect(policy.validate(document), isNull);
      expect(policy.contentTypeFor(document), 'image/webp');
    });
  });
}
