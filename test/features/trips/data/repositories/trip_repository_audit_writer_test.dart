import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/trips/data/models/trip_model.dart';
import 'package:horus_system/features/trips/data/repositories/trip_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('TripRepositoryAuditWriter display name', () {
    test('prefers trimmed loading order number', () async {
      final auditRepository = _CapturingAuditLogRepository();
      final writer = TripRepositoryAuditWriter(
        CreateAuditLogUseCase(auditRepository),
      );

      await writer.writeCreated(
        model: _tripModel(loadingOrderNumber: '  LO-001  ', waybillNumber: 'WB'),
        actorRole: 'owner',
      );

      expect(auditRepository.lastData?.entityDisplayName, 'LO-001');
    });

    test('falls back to trimmed waybill number', () async {
      final auditRepository = _CapturingAuditLogRepository();
      final writer = TripRepositoryAuditWriter(
        CreateAuditLogUseCase(auditRepository),
      );

      await writer.writeCreated(
        model: _tripModel(loadingOrderNumber: '   ', waybillNumber: '  WB-1  '),
        actorRole: 'owner',
      );

      expect(auditRepository.lastData?.entityDisplayName, 'WB-1');
    });

    test('falls back to customer and route', () async {
      final auditRepository = _CapturingAuditLogRepository();
      final writer = TripRepositoryAuditWriter(
        CreateAuditLogUseCase(auditRepository),
      );

      await writer.writeCreated(
        model: _tripModel(customerName: ' Customer ', routeName: ' Route '),
        actorRole: 'owner',
      );

      expect(auditRepository.lastData?.entityDisplayName, 'Customer - Route');
    });

    test('falls back to trip id', () async {
      final auditRepository = _CapturingAuditLogRepository();
      final writer = TripRepositoryAuditWriter(
        CreateAuditLogUseCase(auditRepository),
      );

      await writer.writeCreated(model: _tripModel(), actorRole: 'owner');

      expect(auditRepository.lastData?.entityDisplayName, 'trip-1');
    });
  });
}

TripModel _tripModel({
  String? loadingOrderNumber,
  String? waybillNumber,
  String? customerName,
  String? routeName,
}) {
  return TripModel(
    id: 'trip-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    routeId: 'route-1',
    status: 'created',
    loadingOrderNumber: loadingOrderNumber,
    waybillNumber: waybillNumber,
    customerName: customerName,
    routeName: routeName,
  );
}

class _CapturingAuditLogRepository implements AuditLogRepository {
  AuditLogWriteData? lastData;

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    lastData = data;
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) {
    throw UnimplementedError();
  }
}
