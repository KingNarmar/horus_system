import '../../../../core/utils/result.dart';
import '../entities/audit_log_write_data.dart';

abstract class AuditLogRepository {
  Future<Result<void>> createAuditLog({required AuditLogWriteData data});
}
