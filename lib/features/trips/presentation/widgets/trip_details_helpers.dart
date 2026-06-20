import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../localization/trips_localizations_x.dart';

AuditLog? firstCreatedTripAuditLog(List<AuditLog> activity) {
  for (final log in activity.reversed) {
    if (log.action == AuditAction.created) return log;
  }

  return null;
}

String formatTripDateTime(DateTime? value, String emptyValue) {
  if (value == null) return emptyValue;

  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}

String localizedTripAuditDescription(BuildContext context, AuditLog log) {
  final l10n = context.l10n;
  final actionLabel = l10n.tripAuditActionLabel(log.action.value);
  final entityName =
      _firstText([
        log.entityDisplayName,
        log.newValues?['customer_name'],
        log.oldValues?['customer_name'],
        log.newValues?['route_name'],
        log.oldValues?['route_name'],
      ]) ??
      l10n.tripEmptyValue;

  if (log.action == AuditAction.statusChanged) {
    final oldStatus = l10n.tripAuditValueLabel(
      'status',
      log.metadata?['old_status'] ?? log.oldValues?['status'],
    );
    final newStatus = l10n.tripAuditValueLabel(
      'status',
      log.metadata?['new_status'] ?? log.newValues?['status'],
    );

    return l10n.tripAuditChangeLine(
      l10n.tripStatusHeader,
      oldStatus,
      newStatus,
    );
  }

  return '$actionLabel: $entityName';
}

String? _firstText(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }

  return null;
}
