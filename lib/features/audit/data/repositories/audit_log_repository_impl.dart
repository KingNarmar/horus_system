import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_log_write_data.dart';
import '../../domain/entities/audit_module.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_logs_remote_data_source.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogsRemoteDataSource remoteDataSource;

  const AuditLogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    try {
      await remoteDataSource.createAuditLog(data: data);
      return const Success(null);
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    try {
      final models = await remoteDataSource.getEntityAuditLogs(
        companyId: companyId,
        module: module,
        entityType: entityType,
        entityId: entityId,
      );

      return Success(models.map((model) => model.toEntity()).toList());
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
