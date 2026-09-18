import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/fleet_asset_type.dart';
import '../../domain/entities/fleet_license_document.dart';
import 'fleet_license_document_file_model.dart';

final class FleetLicenseDocumentModel {
  final String id;
  final String companyId;
  final String? tractorHeadId;
  final String? trailerId;
  final List<FleetLicenseDocumentFileModel> files;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final String? removedBy;
  final DateTime? removedAt;
  final String? replacesDocumentId;

  const FleetLicenseDocumentModel({
    required this.id,
    required this.companyId,
    required this.files,
    required this.uploadedAt,
    this.tractorHeadId,
    this.trailerId,
    this.uploadedBy,
    this.removedBy,
    this.removedAt,
    this.replacesDocumentId,
  });

  factory FleetLicenseDocumentModel.fromMap(
    Map<String, dynamic> map, {
    List<FleetLicenseDocumentFileModel> files = const [],
  }) {
    final tractorHeadId = map['tractor_head_id'] as String?;
    final trailerId = map['trailer_id'] as String?;
    if ((tractorHeadId == null) == (trailerId == null)) {
      throw const FormatException('Invalid Fleet license document asset.');
    }

    return FleetLicenseDocumentModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      tractorHeadId: tractorHeadId,
      trailerId: trailerId,
      files: files,
      uploadedBy: map['uploaded_by'] as String?,
      uploadedAt: DbTimestamp.decode(map['uploaded_at'], field: 'uploaded_at'),
      removedBy: map['removed_by'] as String?,
      removedAt: DbTimestamp.decodeNullable(
        map['removed_at'],
        field: 'removed_at',
      ),
      replacesDocumentId: map['replaces_document_id'] as String?,
    );
  }

  FleetLicenseDocumentModel copyWithFiles(
    List<FleetLicenseDocumentFileModel> value,
  ) {
    return FleetLicenseDocumentModel(
      id: id,
      companyId: companyId,
      tractorHeadId: tractorHeadId,
      trailerId: trailerId,
      files: value,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      removedBy: removedBy,
      removedAt: removedAt,
      replacesDocumentId: replacesDocumentId,
    );
  }

  FleetLicenseDocumentFileModel? activeFileById(String fileId) {
    for (final file in files) {
      if (file.id == fileId && file.removedAt == null) return file;
    }
    return null;
  }

  FleetLicenseDocument toEntity() {
    final tractorId = tractorHeadId;
    return FleetLicenseDocument(
      id: id,
      companyId: companyId,
      assetType: tractorId != null
          ? FleetAssetType.tractorHead
          : FleetAssetType.trailer,
      assetId: tractorId ?? trailerId!,
      files: files.map((file) => file.toEntity()).toList(growable: false),
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt,
      removedBy: removedBy,
      removedAt: removedAt,
      replacesDocumentId: replacesDocumentId,
    );
  }
}
