import 'trip_document_kind.dart';

final class TripDocument {
  final String id;
  final String companyId;
  final String tripId;
  final TripDocumentKind kind;
  final String originalFileName;
  final String mimeType;
  final int sizeBytes;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesDocumentId;

  const TripDocument({
    required this.id,
    required this.companyId,
    required this.tripId,
    required this.kind,
    required this.originalFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesDocumentId,
  });

  bool get isActive => removedAt == null;
}
