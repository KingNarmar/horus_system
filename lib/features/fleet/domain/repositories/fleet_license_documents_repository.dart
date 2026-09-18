import 'dart:typed_data';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/result.dart';
import '../entities/fleet_license_document.dart';
import '../entities/fleet_license_document_file_side.dart';
import '../entities/fleet_license_document_target.dart';

abstract class FleetLicenseDocumentsRepository {
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  });

  Future<Result<FleetLicenseDocument>> createWithFile({
    required FleetLicenseDocumentTarget target,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  });

  Future<Result<FleetLicenseDocument>> addFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile file,
    BusinessDate? newLicenseExpiryDate,
  });

  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  });

  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
  });

  Future<Result<FleetLicenseDocument>> replaceFile({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required String fileId,
    required FleetLicenseDocumentFileSide side,
    required BusinessDocumentFile replacement,
    BusinessDate? newLicenseExpiryDate,
  });

  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });
}
