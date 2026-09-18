import 'dart:typed_data';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/result.dart';
import '../entities/fleet_license_document.dart';
import '../entities/fleet_license_document_target.dart';

abstract class FleetLicenseDocumentsRepository {
  Future<Result<FleetLicenseDocument?>> getActiveDocument({
    required FleetLicenseDocumentTarget target,
  });

  Future<Result<FleetLicenseDocument>> upload({
    required FleetLicenseDocumentTarget target,
    required BusinessDocumentFile document,
    BusinessDate? newLicenseExpiryDate,
  });

  Future<Result<BusinessDocumentAccess>> createTemporaryAccess({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });

  Future<Result<Uint8List>> download({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });

  Future<Result<FleetLicenseDocument>> replace({
    required FleetLicenseDocumentTarget target,
    required String documentId,
    required BusinessDocumentFile document,
    BusinessDate? newLicenseExpiryDate,
  });

  Future<Result<void>> remove({
    required FleetLicenseDocumentTarget target,
    required String documentId,
  });
}
