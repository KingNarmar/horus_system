import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../localization/trips_localizations_x.dart';

const List<String> _tripAuditChangeFieldOrder = [
  'status',
  'customer_name',
  'route_name',
  'driver_name',
  'tractor_head_plate_number',
  'trailer_plate_number',
  'loading_order_number',
  'waybill_number',
  'quantity_tons',
  'freight_price',
  'total_expenses',
  'expense_name',
  'expense_type_name',
  'amount',
  'paid_by',
  'expense_date',
  'trip_total_expenses',
  'scheduled_loading_at',
  'scheduled_delivery_at',
  'actual_loading_at',
  'actual_delivery_at',
  'notes',
];

const Set<String> _technicalAuditKeys = {
  'id',
  'company_id',
  'trip_id',
  'expense_id',
  'customer_id',
  'route_id',
  'driver_id',
  'tractor_head_id',
  'trailer_id',
  'expense_type_id',
  'created_at',
  'updated_at',
};

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

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

String localizedTripAuditActionTitle(BuildContext context, AuditLog log) {
  return _localizedAuditActionLabel(context.l10n, log);
}

String localizedTripAuditDescription(BuildContext context, AuditLog log) {
  final l10n = context.l10n;
  final actionLabel = _localizedAuditActionLabel(l10n, log);
  final rawEntityName = _auditEntityName(l10n, log);
  final entityName = _isExpenseAudit(log)
      ? l10n.tripExpenseTypeName(rawEntityName)
      : rawEntityName;

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

  final amount = _firstText([
    log.newValues?['amount'],
    log.metadata?['amount'],
  ]);
  if (amount != null && _isExpenseAudit(log)) {
    return '$entityName - $amount';
  }

  return '$actionLabel: $entityName';
}

bool shouldShowTripAuditChanges(AuditLog log) {
  if (log.action == AuditAction.statusChanged) return false;
  if (log.action == AuditAction.created) return _isExpenseAudit(log);
  return true;
}

bool shouldShowTripAuditDetails(AuditLog log) {
  return log.action == AuditAction.created && _isExpenseAudit(log);
}

List<String> visibleTripAuditChangeKeys(AuditLog log) {
  final oldValues = log.oldValues ?? const <String, Object?>{};
  final newValues = log.newValues ?? const <String, Object?>{};

  final keys = <String>{...oldValues.keys, ...newValues.keys}.where((key) {
    if (_technicalAuditKeys.contains(key)) return false;
    if (!_tripAuditChangeFieldOrder.contains(key)) return false;

    final oldValue = oldValues[key];
    final newValue = newValues[key];

    if (_isEmptyAuditValue(oldValue) && _isEmptyAuditValue(newValue)) {
      return false;
    }

    if (_safeAuditValue(oldValue) == _safeAuditValue(newValue)) {
      return false;
    }

    if (_looksTechnical(oldValue) || _looksTechnical(newValue)) {
      return false;
    }

    return true;
  }).toList();

  keys.sort((a, b) {
    return _tripAuditChangeFieldOrder
        .indexOf(a)
        .compareTo(_tripAuditChangeFieldOrder.indexOf(b));
  });

  return keys;
}

Object? safeTripAuditValue(Object? value) {
  if (_looksTechnical(value)) return null;
  return value;
}

String _auditEntityName(AppLocalizations l10n, AuditLog log) {
  return _firstText([
        log.newValues?['expense_name'],
        log.oldValues?['expense_name'],
        log.metadata?['expense_name'],
        log.newValues?['loading_order_number'],
        log.oldValues?['loading_order_number'],
        log.newValues?['waybill_number'],
        log.oldValues?['waybill_number'],
        log.newValues?['customer_name'],
        log.oldValues?['customer_name'],
        log.newValues?['route_name'],
        log.oldValues?['route_name'],
        log.entityDisplayName,
      ]) ??
      l10n.tripEmptyValue;
}

String _localizedAuditActionLabel(AppLocalizations l10n, AuditLog log) {
  final isArabic = l10n.localeName.startsWith('ar');

  if (_isExpenseAudit(log)) {
    return switch (log.action) {
      AuditAction.created => isArabic ? 'تم إضافة مصروف' : 'Expense added',
      AuditAction.updated => isArabic ? 'تم تعديل مصروف' : 'Expense updated',
      AuditAction.deactivated =>
        isArabic ? 'تم إلغاء تفعيل مصروف' : 'Expense deactivated',
      AuditAction.reactivated =>
        isArabic ? 'تمت إعادة تفعيل مصروف' : 'Expense reactivated',
      AuditAction.statusChanged => l10n.tripAuditActionLabel(log.action.value),
    };
  }

  return switch (log.action) {
    AuditAction.created => isArabic ? 'تم إنشاء الرحلة' : 'Trip created',
    AuditAction.updated => isArabic ? 'تم تعديل الرحلة' : 'Trip updated',
    AuditAction.deactivated =>
      isArabic ? 'تم إلغاء تفعيل الرحلة' : 'Trip deactivated',
    AuditAction.reactivated =>
      isArabic ? 'تمت إعادة تفعيل الرحلة' : 'Trip reactivated',
    AuditAction.statusChanged => l10n.tripAuditActionLabel(log.action.value),
  };
}

bool _isExpenseAudit(AuditLog log) {
  return log.entityDisplayName == 'Trip expense' ||
      log.newValues?.containsKey('expense_name') == true ||
      log.oldValues?.containsKey('expense_name') == true ||
      log.metadata?.containsKey('expense_id') == true;
}

Object? _safeAuditValue(Object? value) {
  if (_isEmptyAuditValue(value)) return null;
  if (_looksTechnical(value)) return null;
  return value;
}

bool _isEmptyAuditValue(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty;
}

bool _looksTechnical(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return false;
  if (_uuidPattern.hasMatch(text)) return true;
  if (text.contains('T') && text.contains(':') && text.length >= 19) {
    return true;
  }

  return false;
}

String? _firstText(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && !_looksTechnical(text)) return text;
  }

  return null;
}
