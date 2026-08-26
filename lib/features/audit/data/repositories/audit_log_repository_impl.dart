import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/audit_entity_type.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/audit_log_write_data.dart';
import '../../domain/entities/audit_module.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_logs_remote_data_source.dart';
import 'audit_log_repository_failure_mapper.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogsRemoteDataSource remoteDataSource;
  final AuditLogRepositoryFailureMapper _failureMapper;

  const AuditLogRepositoryImpl({required this.remoteDataSource})
    : _failureMapper = const AuditLogRepositoryFailureMapper();

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) {
    return _guard(() async {
      await remoteDataSource.createAuditLog(data: data);
      return const Success(null);
    });
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getEntityAuditLogs(
        companyId: companyId,
        module: module,
        entityType: entityType,
        entityId: entityId,
      );

      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
