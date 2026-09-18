import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/trip_document.dart';
import '../../domain/entities/trip_document_kind.dart';
import '../constants/trip_document_db_contract.dart';

final class TripDocumentModel {
  final String id;
  final String companyId;
  final String tripId;
  final TripDocumentKind kind;
  final String storageReference;
  final String originalFileName;
  final String mimeType;
  final int sizeBytes;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesDocumentId;

  const TripDocumentModel({
    required this.id,
    required this.companyId,
    required this.tripId,
    required this.kind,
    required this.storageReference,
    required this.originalFileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesDocumentId,
  });

  factory TripDocumentModel.fromMap(Map<String, dynamic> map) {
    return TripDocumentModel(
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      tripId: map[TripDocumentDbFields.tripId] as String,
      kind: TripDocumentKindX.fromValue(
        map[TripDocumentDbFields.documentKind] as String,
      ),
      storageReference: map[TripDocumentDbFields.storageReference] as String,
      originalFileName: map[TripDocumentDbFields.originalFileName] as String,
      mimeType: map[TripDocumentDbFields.mimeType] as String,
      sizeBytes: (map[TripDocumentDbFields.sizeBytes] as num).toInt(),
      uploadedBy: map[TripDocumentDbFields.uploadedBy] as String?,
      uploadedAt: DateTime.parse(
        map[TripDocumentDbFields.uploadedAt].toString(),
      ),
      removedBy: map[TripDocumentDbFields.removedBy] as String?,
      removedAt: map[TripDocumentDbFields.removedAt] == null
          ? null
          : DateTime.parse(map[TripDocumentDbFields.removedAt].toString()),
      replacesDocumentId:
          map[TripDocumentDbFields.replacesDocumentId] as String?,
    );
  }

  TripDocument toEntity() {
    return TripDocument(
      id: id,
      companyId: companyId,
      tripId: tripId,
      kind: kind,
      originalFileName: originalFileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      removedBy: removedBy,
      removedAt: removedAt,
      replacesDocumentId: replacesDocumentId,
    );
  }
}
