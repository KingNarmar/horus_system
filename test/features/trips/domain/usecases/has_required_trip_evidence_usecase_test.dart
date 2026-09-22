import 'package:horus_system/features/trips/domain/entities/trip_document.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';
import 'package:horus_system/features/trips/domain/usecases/has_required_trip_evidence_usecase.dart';
import 'package:test/test.dart';

void main() {
  const useCase = HasRequiredTripEvidenceUseCase();

  test('returns true for an active waybill', () async {
    final result = await useCase(
      HasRequiredTripEvidenceParams(
        documents: [_document(kind: TripDocumentKind.waybill)],
      ),
    );

    expect(result.dataOrNull, isTrue);
  });

  test('returns true for an active proof of delivery', () async {
    final result = await useCase(
      HasRequiredTripEvidenceParams(
        documents: [_document(kind: TripDocumentKind.proofOfDelivery)],
      ),
    );

    expect(result.dataOrNull, isTrue);
  });

  test('ignores removed evidence documents', () async {
    final result = await useCase(
      HasRequiredTripEvidenceParams(
        documents: [
          _document(
            kind: TripDocumentKind.waybill,
            removedAt: DateTime.utc(2026, 9, 22),
          ),
        ],
      ),
    );

    expect(result.dataOrNull, isFalse);
  });
}

TripDocument _document({required TripDocumentKind kind, DateTime? removedAt}) {
  return TripDocument(
    id: 'document-1',
    companyId: 'company-1',
    tripId: 'trip-1',
    kind: kind,
    originalFileName: 'document.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 100,
    uploadedAt: DateTime.utc(2026, 9, 21),
    removedAt: removedAt,
  );
}
