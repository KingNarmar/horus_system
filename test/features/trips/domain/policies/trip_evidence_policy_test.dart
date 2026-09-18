import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/policies/trip_evidence_policy.dart';

void main() {
  const policy = TripEvidencePolicy();

  group('TripEvidencePolicy', () {
    test('requires waybill or proof of delivery for evidence readiness', () {
      expect(policy.hasRequiredEvidence([_document(TripDocumentKind.waybill)]), isTrue);
      expect(
        policy.hasRequiredEvidence([
          _document(TripDocumentKind.proofOfDelivery),
        ]),
        isTrue,
      );
      expect(
        policy.hasRequiredEvidence([
          _document(TripDocumentKind.loadingOrder),
          _document(TripDocumentKind.other),
        ]),
        isFalse,
      );
    });

    test('ignores logically removed qualifying evidence', () {
      expect(
        policy.hasRequiredEvidence([
          _document(
            TripDocumentKind.waybill,
            removedAt: DateTime.utc(2026, 9, 18),
          ),
        ]),
        isFalse,
      );
    });

    test('protects documents received, invoiced, and paid statuses', () {
      expect(
        policy.requiresEvidenceForStatus(TripStatus.documentsReceived),
        isTrue,
      );
      expect(policy.requiresEvidenceForStatus(TripStatus.invoiced), isTrue);
      expect(policy.requiresEvidenceForStatus(TripStatus.paid), isTrue);
      expect(policy.requiresEvidenceForStatus(TripStatus.delivered), isFalse);
      expect(policy.requiresEvidenceForStatus(TripStatus.cancelled), isFalse);
    });

    test('limits active documents to ten', () {
      final nine = List.generate(
        9,
        (index) => _document(
          TripDocumentKind.other,
          id: 'document-$index',
        ),
      );
      final ten = List.generate(
        10,
        (index) => _document(
          TripDocumentKind.other,
          id: 'document-$index',
        ),
      );

      expect(policy.canUpload(nine), isTrue);
      expect(policy.canUpload(ten), isFalse);
    });

    test('cannot remove the last qualifying evidence from protected status', () {
      final waybill = _document(TripDocumentKind.waybill, id: 'waybill');
      final other = _document(TripDocumentKind.other, id: 'other');

      expect(
        policy.canRemove(
          currentStatus: TripStatus.documentsReceived,
          documents: [waybill, other],
          documentId: waybill.id,
        ),
        isFalse,
      );

      final proof = _document(
        TripDocumentKind.proofOfDelivery,
        id: 'proof',
      );
      expect(
        policy.canRemove(
          currentStatus: TripStatus.invoiced,
          documents: [waybill, proof],
          documentId: waybill.id,
        ),
        isTrue,
      );
    });
  });
}

TripDocument _document(
  TripDocumentKind kind, {
  String id = 'document',
  DateTime? removedAt,
}) {
  return TripDocument(
    id: id,
    companyId: 'company',
    tripId: 'trip',
    kind: kind,
    originalFileName: 'document.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 128,
    uploadedAt: DateTime.utc(2026, 9, 18),
    removedAt: removedAt,
  );
}
