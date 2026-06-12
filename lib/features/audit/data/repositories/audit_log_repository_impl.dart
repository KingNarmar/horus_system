import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/audit_log_write_data.dart';
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
        ServerFailure(message: error.message, code: error.code),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
