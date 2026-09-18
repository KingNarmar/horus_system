import 'package:horus_system/features/fleet/data/models/fleet_license_document_model.dart';
import 'package:horus_system/features/fleet/domain/entities/fleet_asset_type.dart';
import 'package:test/test.dart';

void main() {
  group('FleetLicenseDocumentModel', () {
    test('maps Tractor Head document without leaking storage reference', () {
      final model = FleetLicenseDocumentModel.fromMap({
        'id': 'document-1',
        'company_id': 'company-1',
        'tractor_head_id': 'tractor-1',
        'trailer_id': null,
        'storage_reference': 'companies/company/tractor-heads/id/license/file.pdf',
        'original_file_name': 'license.pdf',
        'mime_type': 'application/pdf',
        'size_bytes': 12,
        'uploaded_by': 'user-1',
        'uploaded_at': '2026-09-18T12:00:00Z',
        'removed_by': null,
        'removed_at': null,
        'replaces_document_id': null,
      });

      final entity = model.toEntity();

      expect(entity.assetType, FleetAssetType.tractorHead);
      expect(entity.assetId, 'tractor-1');
      expect(entity.originalFileName, 'license.pdf');
      expect(entity.isActive, isTrue);
    });

    test('maps Trailer document', () {
      final model = FleetLicenseDocumentModel.fromMap({
        'id': 'document-1',
        'company_id': 'company-1',
        'tractor_head_id': null,
        'trailer_id': 'trailer-1',
        'storage_reference': 'companies/company/trailers/id/license/file.pdf',
        'original_file_name': 'license.jpg',
        'mime_type': 'image/jpeg',
        'size_bytes': 12,
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
          'storage_reference': 'reference',
          'original_file_name': 'license.pdf',
          'mime_type': 'application/pdf',
          'size_bytes': 12,
          'uploaded_at': '2026-09-18T12:00:00Z',
        }),
        throwsFormatException,
      );
    });
  });
}
