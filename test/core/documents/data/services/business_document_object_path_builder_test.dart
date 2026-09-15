import 'package:horus_system/core/documents/data/services/business_document_object_path_builder.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_location.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_reference.dart';
import 'package:horus_system/core/documents/domain/failures/business_document_failure_codes.dart';
import 'package:test/test.dart';

void main() {
  const companyId = '11111111-1111-1111-1111-111111111111';
  const entityId = '22222222-2222-2222-2222-222222222222';
  final builder = BusinessDocumentObjectPathBuilder(
    tokenFactory: () => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );

  group('BusinessDocumentObjectPathBuilder', () {
    test('builds canonical company-scoped object keys', () {
      final result = builder.build(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: 'Trips',
          entityId: entityId,
          documentKind: 'Delivery-Evidence',
        ),
        fileName: 'proof.PDF',
      );

      expect(
        result.dataOrNull,
        'companies/$companyId/trips/$entityId/delivery-evidence/'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf',
      );
    });

    test('rejects unsafe path segments', () {
      final result = builder.build(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: '../trips',
          entityId: entityId,
          documentKind: 'evidence',
        ),
        fileName: 'proof.pdf',
      );

      expect(
        result.failureOrNull?.code,
        BusinessDocumentFailureCodes.validationLocationInvalid,
      );
    });

    test('rejects invalid company and entity identifiers', () {
      final invalidCompany = builder.build(
        location: const BusinessDocumentLocation(
          companyId: 'company-1',
          scope: 'trips',
          entityId: entityId,
          documentKind: 'evidence',
        ),
        fileName: 'proof.pdf',
      );
      final invalidEntity = builder.build(
        location: const BusinessDocumentLocation(
          companyId: companyId,
          scope: 'trips',
          entityId: 'trip-1',
          documentKind: 'evidence',
        ),
        fileName: 'proof.pdf',
      );

      expect(
        invalidCompany.failureOrNull?.code,
        BusinessDocumentFailureCodes.validationLocationInvalid,
      );
      expect(
        invalidEntity.failureOrNull?.code,
        BusinessDocumentFailureCodes.validationLocationInvalid,
      );
    });

    test('accepts only references in the requested tenant', () {
      const objectKey =
          'companies/$companyId/trips/$entityId/evidence/'
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pdf';
      const reference = BusinessDocumentReference(objectKey);

      expect(
        builder.validateReference(companyId: companyId, reference: reference),
        isNull,
      );
      expect(
        builder
            .validateReference(
              companyId: '33333333-3333-3333-3333-333333333333',
              reference: reference,
            )
            ?.code,
        BusinessDocumentFailureCodes.permissionAccess,
      );
    });

    test('rejects malformed stored references before remote access', () {
      const reference = BusinessDocumentReference(
        'companies/$companyId/trips/$entityId/evidence/../proof.pdf',
      );

      expect(
        builder
            .validateReference(companyId: companyId, reference: reference)
            ?.code,
        BusinessDocumentFailureCodes.validationReferenceInvalid,
      );
    });
  });
}
