import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_compensation_revision.dart';
import '../entities/driver_compensation_write_data.dart';

abstract class DriverCompensationRepository {
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  });

  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  });

  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  });

  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  });

  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  });
}
