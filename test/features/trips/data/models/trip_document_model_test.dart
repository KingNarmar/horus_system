import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/trips/data/models/trip_document_model.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';

void main() {
  test('maps trip document metadata without leaking storage reference to Domain', () {
    final model = TripDocumentModel.fromMap({
      'id': 'document-1',
      'company_id': 'company-1',
      'trip_id': 'trip-1',
      'document_kind': 'proof_of_delivery',
      'storage_reference':
          'companies/company-1/trips/trip-1/proof_of_delivery/token.pdf',
      'original_file_name': 'pod.pdf',
      'mime_type': 'application/pdf',
      'size_bytes': 1024,
      'uploaded_by': 'user-1',
      'uploaded_at': '2026-09-18T10:00:00Z',
      'removed_by': null,
      'removed_at': null,
      'replaces_document_id': 'document-0',
    });

    final entity = model.toEntity();

    expect(entity.id, 'document-1');
    expect(entity.companyId, 'company-1');
    expect(entity.tripId, 'trip-1');
    expect(entity.kind, TripDocumentKind.proofOfDelivery);
    expect(entity.originalFileName, 'pod.pdf');
    expect(entity.sizeBytes, 1024);
    expect(entity.replacesDocumentId, 'document-0');
    expect(entity.isActive, isTrue);
  });
}
