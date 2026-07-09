import 'package:horus_system/core/errors/failure_codes.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/audit_entity_type.dart';
import '../entities/audit_log.dart';
import '../entities/audit_module.dart';
import '../repositories/audit_log_repository.dart';

class GetEntityAuditLogsParams {
  final String companyId;
  final AuditModule module;
  final AuditEntityType entityType;
  final String entityId;

  const GetEntityAuditLogsParams({
    required this.companyId,
    required this.module,
    required this.entityType,
    required this.entityId,
  });
}

class GetEntityAuditLogsUseCase
    implements UseCase<List<AuditLog>, GetEntityAuditLogsParams> {
  final AuditLogRepository _repository;

  const GetEntityAuditLogsUseCase(this._repository);

  @override
  Future<Result<List<AuditLog>>> call(GetEntityAuditLogsParams params) {
    if (params.companyId.trim().isEmpty) {
      return Future.value(
        const FailureResult<List<AuditLog>>(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired),
        ),
      );
    }

    if (params.entityId.trim().isEmpty) {
      return Future.value(
        const FailureResult<List<AuditLog>>(
          ValidationFailure(code: FailureCodes.validationAuditEntityIdRequired),
        ),
      );
    }

    return _repository.getEntityAuditLogs(
      companyId: params.companyId.trim(),
      module: params.module,
      entityType: params.entityType,
      entityId: params.entityId.trim(),
    );
  }
}
