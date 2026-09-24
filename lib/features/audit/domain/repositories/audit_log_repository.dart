import '../../../../core/utils/result.dart';
import '../entities/audit_entity_type.dart';
import '../entities/audit_log.dart';
import '../entities/audit_module.dart';

abstract class AuditLogRepository {
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  });
}
