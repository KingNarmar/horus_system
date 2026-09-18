import 'package:horus_system/features/fleet/data/models/fleet_license_document_file_model.dart';
import 'package:horus_system/features/fleet/data/models/fleet_license_document_model.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_asset_type.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_license_document_file_side.dart';
import 'package:test/test.dart';

void main() {
  group('FleetLicenseDocumentModel', () {
    test('maps Tractor Head aggregate with front/back child files', () {
      final model = FleetLicenseDocumentModel.fromMap(
        {
          'id': 'document-1',
          'company_id': 'company-1',
          'tractor_head_id': 'tractor-1',
          'trailer_id': null,
          'uploaded_by': 'user-1',
          'uploaded_at': '2026-09-18T12:00:00Z',
          'removed_by': null,
          'removed_at': null,
          'replaces_document_id': null,
        },
        files: [
          _fileModel(
            id: 'front-file',
            side: FleetLicenseDocumentFileSide.front,
            name: 'front.pdf',
          ),
          _fileModel(
            id: 'back-file',
            side: FleetLicenseDocumentFileSide.back,
            name: 'back.pdf',
          ),
        ],
      );

      final entity = model.toEntity();

      expect(entity.assetType, FleetAssetType.tractorHead);
      expect(entity.assetId, 'tractor-1');
      expect(entity.frontFile?.originalFileName, 'front.pdf');
      expect(entity.backFile?.originalFileName, 'back.pdf');
      expect(entity.combinedFile, isNull);
      expect(entity.isActive, isTrue);
    });

    test('maps legacy combined file without leaking storage reference', () {
      final fileModel = _fileModel(
        id: 'combined-file',
        side: FleetLicenseDocumentFileSide.combined,
        name: 'legacy.pdf',
      );
      final entity = fileModel.toEntity();

      expect(entity.side, FleetLicenseDocumentFileSide.combined);
      expect(entity.originalFileName, 'legacy.pdf');
      expect(
        entity.toString(),
        isNot(contains(fileModel.storageReference)),
      );
    });

    test('maps Trailer document', () {
      final model = FleetLicenseDocumentModel.fromMap({
        'id': 'document-1',
        'company_id': 'company-1',
        'tractor_head_id': null,
        'trailer_id': 'trailer-1',
        'uploaded_by': null,
        'uploaded_at': '2026-09-18T12:00:00Z',
        'removed_by': null,
        'removed_at': null,
        'replaces_document_id': null,
      });

      expect(model.toEntity().assetType, FleetAssetType.trailer);
      expect(model.toEntity().assetId, 'trailer-1');
    });

    test('rejects rows with both asset foreign keys populated', () {
      expect(
        () => FleetLicenseDocumentModel.fromMap({
          'id': 'document-1',
          'company_id': 'company-1',
          'tractor_head_id': 'tractor-1',
          'trailer_id': 'trailer-1',
          'uploaded_at': '2026-09-18T12:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });
}

FleetLicenseDocumentFileModel _fileModel({
  required String id,
  required FleetLicenseDocumentFileSide side,
  required String name,
}) {
  return FleetLicenseDocumentFileModel(
    id: id,
    companyId: 'company-1',
    licenseDocumentId: 'document-1',
    side: side,
    storageReference:
        'companies/11111111-1111-1111-1111-111111111111/'
        'tractor-heads/22222222-2222-2222-2222-222222222222/'
        'license/0123456789abcdef0123456789abcdef.pdf',
    originalFileName: name,
    mimeType: 'application/pdf',
    sizeBytes: 12,
    uploadedAt: DateTime.utc(2026, 9, 18),
  );
}
