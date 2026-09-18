import '../entities/trip_document.dart';
import '../entities/trip_document_kind.dart';
import '../entities/trip_status.dart';

final class TripEvidencePolicy {
  static const int maxActiveDocuments = 10;

  const TripEvidencePolicy();

  bool hasRequiredEvidence(Iterable<TripDocument> documents) {
    return documents.any(
      (document) =>
          document.isActive &&
          (document.kind == TripDocumentKind.waybill ||
              document.kind == TripDocumentKind.proofOfDelivery),
    );
  }

  bool requiresEvidenceForStatus(TripStatus status) {
    return switch (status) {
      TripStatus.documentsReceived ||
      TripStatus.invoiced ||
      TripStatus.paid => true,
      TripStatus.created ||
      TripStatus.assigned ||
      TripStatus.loaded ||
      TripStatus.onRoad ||
      TripStatus.arrived ||
      TripStatus.delivered ||
      TripStatus.cancelled => false,
    };
  }

  bool canUpload(Iterable<TripDocument> documents) {
    return documents.where((document) => document.isActive).length <
        maxActiveDocuments;
  }

  bool canRemove({
    required TripStatus currentStatus,
    required Iterable<TripDocument> documents,
    required String documentId,
  }) {
    if (!requiresEvidenceForStatus(currentStatus)) return true;

    return hasRequiredEvidence(
      documents.where(
        (document) => document.isActive && document.id != documentId,
      ),
    );
  }
}
