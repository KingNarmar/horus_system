import 'dart:async';

import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';

import 'fake_business_time_zone_converter.dart';

final class DeferredActivityRepository implements AuditLogRepository {
  final requests = <Completer<Result<List<AuditLog>>>>[];
  final companyIds = <String>[];
  final modules = <AuditModule>[];
  final entityTypes = <AuditEntityType>[];
  final entityIds = <String>[];
  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) {
    companyIds.add(companyId);
    modules.add(module);
    entityTypes.add(entityType);
    entityIds.add(entityId);
    final request = Completer<Result<List<AuditLog>>>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) =>
      throw UnimplementedError();
}

final class RecordingActivityConverter implements BusinessTimeZoneConverter {
  final timeZoneIds = <String>[];
  Failure? failure;
  void Function()? onConvert;
  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) {
    timeZoneIds.add(timeZoneId);
    onConvert?.call();
    if (failure != null) return FailureResult(failure!);
    return FakeBusinessTimeZoneConverter(
      offset: timeZoneId == 'Asia/Dubai'
          ? const Duration(hours: 4)
          : Duration.zero,
    ).toBusinessLocalDateTime(instant: instant, timeZoneId: timeZoneId);
  }

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) => throw UnimplementedError();
}
