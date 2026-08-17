import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../../../driver_finance/domain/entities/driver_finance_trip_option.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement_type.dart';
import '../../../driver_finance/presentation/localization/driver_finance_localizations_x.dart';
import '../localization/drivers_localizations_x.dart';

const _driverFinancialMovementEntityKey = 'driver_financial_movement';
const _legacyDriverFinancialMovementEntityDisplayName =
    'Driver financial movement';
const _driverFinanceMovementAddedEvent = 'driver_finance_movement_added';

class DriverActivityTimelineItem extends StatelessWidget {
  final AuditLog log;
  final List<DriverFinanceTripOption> tripOptions;

  const DriverActivityTimelineItem({
    required this.log,
    required this.tripOptions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final financeSummary = _financeSummary(l10n);
    final changes = financeSummary == null
        ? _changedFields(log, l10n)
        : const <Widget>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            financeSummary?.title ?? l10n.auditActionLabel(log.action.value),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.auditTimelineHeader(
              _actorName(log, l10n),
              l10n.auditRoleDisplayLabel(log.actorRole),
              _formatDateTime(context, log.createdAt),
            ),
          ),
          if (financeSummary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ...financeSummary.details.map((detail) => Text(detail)),
          ] else if (changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...changes,
          ],
        ],
      ),
    );
  }

  _DriverFinanceLogSummary? _financeSummary(AppLocalizations l10n) {
    if (!_isDriverFinanceLog(log)) return null;

    final typeValue = _firstText([
      log.metadata?['movement_type'],
      log.newValues?['movement_type'],
    ]);
    if (typeValue == null) return null;

    late final DriverFinancialMovementType type;
    try {
      type = driverFinancialMovementTypeFromValue(typeValue);
    } catch (_) {
      return null;
    }

    final amount = _firstText([
      log.metadata?['amount'],
      log.newValues?['amount'],
    ]);
    final date = _firstText([log.newValues?['movement_date']]);
    final tripId = _firstText([
      log.metadata?['trip_id'],
      log.newValues?['trip_id'],
    ]);
    final notes = _firstText([log.newValues?['notes']]);
    final titleParts = <String>[l10n.driverMovementTypeLabel(type), ?amount];
    final details = <String>[
      if (date != null) _detailLine(l10n.driverMovementDateLabel, date),
      if (tripId != null)
        _detailLine(l10n.driverMovementTripLine, _tripLabel(tripId)),
      if (notes != null) _detailLine(l10n.driverMovementNotesLabel, notes),
    ];

    return _DriverFinanceLogSummary(
      title: titleParts.join(' - '),
      details: details,
    );
  }

  bool _isDriverFinanceLog(AuditLog log) {
    return log.entityDisplayName == _driverFinancialMovementEntityKey ||
        log.entityDisplayName ==
            _legacyDriverFinancialMovementEntityDisplayName ||
        log.metadata?['audit_event'] == _driverFinanceMovementAddedEvent ||
        log.metadata?.containsKey('movement_id') == true ||
        log.newValues?.containsKey('movement_type') == true;
  }

  String _tripLabel(String tripId) {
    for (final option in tripOptions) {
      if (option.id == tripId) return option.label;
    }
    return tripId;
  }

  String _detailLine(String label, String value) => '$label: $value';

  String? _firstText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  List<Widget> _changedFields(AuditLog log, AppLocalizations l10n) {
    const textFields = [
      'full_name',
      'phone',
      'national_id',
      'license_number',
      'license_expiry_date',
      'notes',
      'is_active',
    ];
    final changes = [
      ...AuditChangeBuilder.buildChanges(
        log: log,
        visibleKeys: textFields,
        fieldLabelBuilder: l10n.driverFieldLabel,
        valueLabelBuilder: l10n.driverValueLabel,
        valuesEqualBuilder: _driverValuesEqual,
      ),
      ..._driverImageChanges(log, l10n),
    ];
    return changes.map((change) {
      return Text(
        l10n.auditChangeLine(change.label, change.oldValue, change.newValue),
      );
    }).toList();
  }

  bool _driverValuesEqual(String key, Object? oldValue, Object? newValue) {
    if (key == 'license_expiry_date') {
      if (_isLegacyUtcDateShift(oldValue, newValue)) return true;
      return _dateOnlyText(oldValue) == _dateOnlyText(newValue);
    }
    return oldValue?.toString() == newValue?.toString();
  }

  List<AuditChange> _driverImageChanges(AuditLog log, AppLocalizations l10n) {
    return [
      _driverImageChange(log, l10n, 'profile_image_path'),
      _driverImageChange(log, l10n, 'license_image_path'),
      _driverImageChange(log, l10n, 'license_back_image_path'),
      _driverImageChange(log, l10n, 'national_id_image_path'),
      _driverImageChange(log, l10n, 'national_id_back_image_path'),
    ].whereType<AuditChange>().toList();
  }

  AuditChange? _driverImageChange(
    AuditLog log,
    AppLocalizations l10n,
    String key,
  ) {
    final oldValue = log.oldValues?[key]?.toString().trim();
    final newValue = log.newValues?[key]?.toString().trim();
    if (oldValue == newValue) return null;

    final hasOld = oldValue != null && oldValue.isNotEmpty;
    final hasNew = newValue != null && newValue.isNotEmpty;
    return AuditChange(
      label: l10n.driverFieldLabel(key),
      oldValue: hasOld ? l10n.driverExistingImageValue : l10n.emptyValue,
      newValue: hasNew ? l10n.driverUpdatedImageValue : l10n.emptyValue,
    );
  }

  String? _dateOnlyText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  bool _isLegacyUtcDateShift(Object? oldValue, Object? newValue) {
    final oldText = oldValue?.toString().trim();
    final newText = newValue?.toString().trim();
    if (oldText == null || newText == null) return false;
    if (!oldText.contains('T20:00:00') || !newText.contains('T20:00:00')) {
      return false;
    }

    final oldDate = DateTime.tryParse(_dateOnlyText(oldText) ?? '');
    final newDate = DateTime.tryParse(_dateOnlyText(newText) ?? '');
    if (oldDate == null || newDate == null) return false;

    return oldDate.difference(newDate).inDays.abs() == 1;
  }

  String _actorName(AuditLog log, AppLocalizations l10n) {
    final name = log.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.unknownUser;
  }
}

class _DriverFinanceLogSummary {
  final String title;
  final List<String> details;

  const _DriverFinanceLogSummary({required this.title, required this.details});
}

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
