import 'package:horus_system/core/errors/failure_codes.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/audit_log_write_data.dart';
import '../repositories/audit_log_repository.dart';

class CreateAuditLogParams {
  final AuditLogWriteData data;

  const CreateAuditLogParams({required this.data});
}

class CreateAuditLogUseCase implements UseCase<void, CreateAuditLogParams> {
  final AuditLogRepository _repository;

  const CreateAuditLogUseCase(this._repository);

  @override
  Future<Result<void>> call(CreateAuditLogParams params) {
    final data = params.data;

    if (data.companyId.trim().isEmpty) {
      return Future.value(
        const FailureResult<void>(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired),
        ),
      );
    }

    if (data.entityId.trim().isEmpty) {
      return Future.value(
        const FailureResult<void>(
          ValidationFailure(
            code: FailureCodes.validationAuditEntityIdRequired,
          ),
        ),
      );
    }

    if (data.description.trim().isEmpty) {
      return Future.value(
        const FailureResult<void>(
          ValidationFailure(
            code: FailureCodes.validationAuditDescriptionRequired,
          ),
        ),
      );
    }

    return _repository.createAuditLog(data: data);
  }
}
