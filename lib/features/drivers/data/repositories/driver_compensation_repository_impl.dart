import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/uuid_v4.dart';
import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/documents/domain/entities/business_document_location.dart';
import '../../../../core/documents/domain/entities/business_document_reference.dart';
import '../../../../core/documents/domain/repositories/business_document_repository.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../../domain/entities/driver_compensation_write_data.dart';
import '../../domain/failures/driver_compensation_failure_codes.dart';
import '../../domain/repositories/driver_compensation_repository.dart';
import '../datasources/driver_compensation_remote_data_source.dart';
import '../mappers/driver_compensation_mapper.dart';
import '../models/driver_compensation_model.dart';
import 'driver_compensation_audit_writer.dart';
import 'driver_compensation_repository_failure_mapper.dart';

final class DriverCompensationRepositoryImpl
    implements DriverCompensationRepository {
  static const String _documentScope = 'driver-compensation';
  static const String _contractDocumentKind = 'employment-contract';

  final DriverCompensationRemoteDataSource remoteDataSource;
  final BusinessDocumentRepository businessDocumentRepository;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final DriverCompensationRepositoryFailureMapper failureMapper;

  const DriverCompensationRepositoryImpl({
    required this.remoteDataSource,
    required this.businessDocumentRepository,
    required this.createAuditLogUseCase,
    this.failureMapper = const DriverCompensationRepositoryFailureMapper(),
  });

  DriverCompensationAuditWriter get _auditWriter =>
      DriverCompensationAuditWriter(createAuditLogUseCase);

  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) {
    return _guard(
      permissionCode: DriverCompensationFailureCodes.permissionView,
      action: () async {
        final models = await remoteDataSource.getHistory(
          companyId: companyId,
          driverId: driverId,
        );
        return Success(models.map((model) => model.toEntity()).toList());
      },
    );
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) async {
    final revisionId = newUuidV4();
    BusinessDocumentReference? uploadedReference;

    if (contractDocument != null) {
      final uploadResult = await businessDocumentRepository.upload(
        location: BusinessDocumentLocation(
          companyId: data.companyId,
          scope: _documentScope,
          entityId: revisionId,
          documentKind: _contractDocumentKind,
        ),
        file: contractDocument,
      );
      final uploadFailure = uploadResult.failureOrNull;
      if (uploadFailure != null) return FailureResult(uploadFailure);
      uploadedReference = uploadResult.dataOrNull;
      if (uploadedReference == null) {
        return const FailureResult(
          UnexpectedFailure(
            code: DriverCompensationFailureCodes.unexpectedError,
          ),
        );
      }
    }

    try {
      final model = await remoteDataSource.createRevision(
        revisionId: revisionId,
        data: data,
        contractDocumentReference: uploadedReference,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.created,
        event: DriverCompensationAuditWriter.revisionCreatedEvent,
      );
    } on PostgrestException catch (error) {
      await _deleteUploadedReference(
        companyId: data.companyId,
        reference: uploadedReference,
      );
      return FailureResult(
        failureMapper.fromPostgrest(
          error,
          permissionCode: DriverCompensationFailureCodes.permissionManage,
        ),
      );
    } catch (error) {
      await _deleteUploadedReference(
        companyId: data.companyId,
        reference: uploadedReference,
      );
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required dynamic effectiveTo,
  }) {
    return _guard(
      permissionCode: DriverCompensationFailureCodes.permissionManage,
      action: () async {
        final oldModel = await remoteDataSource.getById(
          companyId: companyId,
          revisionId: revisionId,
          driverId: driverId,
        );
        final model = await remoteDataSource.endRevision(
          companyId: companyId,
          revisionId: revisionId,
          driverId: driverId,
          effectiveTo: effectiveTo,
        );
        return _withAudit(
          model: model,
          actorRole: actorRole,
          action: AuditAction.updated,
          event: DriverCompensationAuditWriter.revisionEndedEvent,
          oldValues: oldModel.toAuditValues(),
        );
      },
    );
  }

  @override
  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  }) async {
    final oldModelResult = await _guard<DriverCompensationModel>(
      permissionCode: DriverCompensationFailureCodes.permissionManage,
      action: () async => Success(
        await remoteDataSource.getById(
          companyId: revision.companyId,
          revisionId: revision.id,
          driverId: revision.driverId,
        ),
      ),
    );
    final oldModelFailure = oldModelResult.failureOrNull;
    if (oldModelFailure != null) return FailureResult(oldModelFailure);
    final oldModel = oldModelResult.dataOrNull;
    if (oldModel == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: DriverCompensationFailureCodes.unexpectedError,
        ),
      );
    }

    final uploadResult = await businessDocumentRepository.upload(
      location: BusinessDocumentLocation(
        companyId: revision.companyId,
        scope: _documentScope,
        entityId: revision.id,
        documentKind: _contractDocumentKind,
      ),
      file: document,
    );
    final uploadFailure = uploadResult.failureOrNull;
    if (uploadFailure != null) return FailureResult(uploadFailure);
    final uploadedReference = uploadResult.dataOrNull;
    if (uploadedReference == null) {
      return const FailureResult(
        UnexpectedFailure(
          code: DriverCompensationFailureCodes.unexpectedError,
        ),
      );
    }

    try {
      final model = await remoteDataSource.attachContractDocument(
        companyId: revision.companyId,
        revisionId: revision.id,
        driverId: revision.driverId,
        reference: uploadedReference,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.updated,
        event: DriverCompensationAuditWriter.contractAttachedEvent,
        oldValues: oldModel.toAuditValues(),
      );
    } on PostgrestException catch (error) {
      await _deleteUploadedReference(
        companyId: revision.companyId,
        reference: uploadedReference,
      );
      return FailureResult(
        failureMapper.fromPostgrest(
          error,
          permissionCode: DriverCompensationFailureCodes.permissionManage,
        ),
      );
    } catch (error) {
      await _deleteUploadedReference(
        companyId: revision.companyId,
        reference: uploadedReference,
      );
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  }) async {
    final reference = revision.contractDocumentReference;
    if (reference == null) {
      return const FailureResult(
        NotFoundFailure(
          code: DriverCompensationFailureCodes.notFoundDocument,
        ),
      );
    }
    return businessDocumentRepository.createTemporaryAccess(
      companyId: companyId,
      reference: reference,
    );
  }

  Future<Result<DriverCompensationRevision>> _withAudit({
    required DriverCompensationModel model,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final auditFailure = await _auditWriter.write(
      model: model,
      actorRole: actorRole,
      action: action,
      event: event,
      oldValues: oldValues,
    );
    if (auditFailure != null) return FailureResult(auditFailure);
    return Success(model.toEntity());
  }

  Future<void> _deleteUploadedReference({
    required String companyId,
    required BusinessDocumentReference? reference,
  }) async {
    if (reference == null) return;
    await businessDocumentRepository.delete(
      companyId: companyId,
      reference: reference,
    );
  }

  Future<Result<T>> _guard<T>({
    required String permissionCode,
    required Future<Result<T>> Function() action,
  }) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        failureMapper.fromPostgrest(error, permissionCode: permissionCode),
      );
    } catch (error) {
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }
}
