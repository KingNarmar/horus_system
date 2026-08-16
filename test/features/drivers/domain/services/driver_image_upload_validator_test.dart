import 'dart:typed_data';

import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_file.dart';
import 'package:horus_system/features/drivers/domain/services/driver_image_upload_validator.dart';
import 'package:test/test.dart';

void main() {
  group('DriverImageUploadValidator', () {
    const validator = DriverImageUploadValidator();

    test('accepts supported images within the storage limit', () {
      final failure = validator.validateImage(
        DriverImageFile(
          bytes: Uint8List(1024),
          fileName: 'national-id-back.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      expect(failure, isNull);
    });

    test('rejects images larger than the storage limit', () {
      final failure = validator.validateImage(
        DriverImageFile(
          bytes: Uint8List(DriverImageUploadValidator.maxImageBytes + 1),
          fileName: 'national-id-back.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      expect(failure?.code, FailureCodes.validationDriverImageTooLarge);
    });

    test('rejects unsupported file extensions', () {
      final failure = validator.validateImage(
        DriverImageFile(
          bytes: Uint8List(1024),
          fileName: 'national-id-back.pdf',
          mimeType: 'application/pdf',
        ),
      );

      expect(failure?.code, FailureCodes.validationDriverImageTypeUnsupported);
    });
  });
}
