import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/business_local_date_time_date_time_adapter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../../../driver_finance/domain/entities/driver_finance_trip_option.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement_type.dart';
import '../../../driver_finance/presentation/localization/driver_finance_localizations_x.dart';
import '../localization/driver_compensation_localizations.dart';
import '../localization/drivers_localizations_x.dart';

const _driverFinancialMovementEntityKey = 'driver_financial_movement';
const _legacyDriverFinancialMovementEntityDisplayName =
    'Driver financial movement';
const _driverFinanceMovementAddedEvent = 'driver_finance_movement_added';
const _driverCompensationCreatedEvent =
    'driver_compensation_revision_created';
const _driverCompensationEndedEvent = 'driver_compensation_revision_ended';
const _driverCompensationContractAttachedEvent =
    'driver_compensation_contract_attached';

class DriverActivityTimelineItem extends StatelessWidget {
  static const MoneyDecimalCodec _moneyCodec = MoneyDecimalCodec();

  final AuditLog log;
  final BusinessLocalDateTime? createdAt;
  final List<DriverFinanceTripOption> tripOptions;

  const DriverActivityTimelineItem({
    required this.log,
    required this.createdAt,
    required this.tripOptions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compensationSummary = _compensationSummary(context);
    final financeSummary = compensationSummary == null
        ? _financeSummary(l10n)
        : null;
    final summary = compensationSummary ?? financeSummary;
    final changes = summary == null
        ? _changedFields(log, l10n)
        : const <Widget>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary?.title ?? l10n.auditActionLabel(log.action.value),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.auditTimelineHeader(
              _actorName(log, l10n),
              l10n.auditRoleDisplayLabel(log.actorRole),
              _formatBusinessLocalDateTime(
                context,
                createdAt,
                l10n.notAvailable,
              ),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ...summary.details.map((detail) => Text(detail)),
          ] else if (changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...changes,
          ],
        ],
      ),
    );
  }

  _DriverActivityLogSummary? _compensationSummary(BuildContext context) {
    final event = log.metadata?['audit_event']?.toString().trim();
    if (event != _driverCompensationCreatedEvent &&
        event != _driverCompensationEndedEvent &&
        event != _driverCompensationContractAttachedEvent) {
      return null;
    }

    final l10n = context.driverCompensationL10n;
    final title = switch (event) {
      _driverCompensationCreatedEvent => l10n.addRevisionTitle,
      _driverCompensationEndedEvent => l10n.endRevisionTitle,
      _driverCompensationContractAttachedEvent => l10n.attachContractDocument,
      _ => l10n.sectionTitle,
    };
    final details = <String>[];
    final amount = _compensationAmount(log.newValues);
    final effectiveFrom = _firstText([log.newValues?['effective_from']]);
    final effectiveTo = _firstText([log.newValues?['effective_to']]);
    final contractReference = _firstText([
      log.newValues?['contract_reference'],
    ]);

    if (amount != null) details.add(_detailLine(l10n.amountLabel, amount));
    if (effectiveFrom != null) {
      details.add(_detailLine(l10n.effectiveFromLabel, effectiveFrom));
    }
    if (effectiveTo != null) {
      details.add(_detailLine(l10n.effectiveToLabel, effectiveTo));
    }
    if (contractReference != null) {
      details.add(
        _detailLine(l10n.contractReferenceLabel, contractReference),
      );
    }

    return _DriverActivityLogSummary(title: title, details: details);
  }

  String? _compensationAmount(Map<String, Object?>? values) {
    if (values == null) return null;
    final minorUnits = int.tryParse(
      values['amount_minor_units']?.toString() ?? '',
    );
    final fractionDigits = int.tryParse(
      values['currency_fraction_digits']?.toString() ?? '',
    );
    final currency = CurrencyCode.tryParse(
      values['currency_code']?.toString() ?? '',
    );
    if (minorUnits == null ||
        fractionDigits == null ||
        currency == null ||
        fractionDigits < CurrencyConfiguration.minFractionDigits ||
        fractionDigits > CurrencyConfiguration.maxFractionDigits) {
      return null;
    }

    final money = Money(minorUnits: minorUnits, currency: currency);
    final configuration = CurrencyConfiguration(
      currency: currency,
      fractionDigits: fractionDigits,
    );
    final value = _moneyCodec.encodeNonNegative(
      money,
      configuration: configuration,
    );
    return '$value ${currency.value}';
  }

  _DriverActivityLogSummary? _financeSummary(AppLocalizations l10n) {
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

    return _DriverActivityLogSummary(
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

class _DriverActivityLogSummary {
  final String title;
  final List<String> details;

  const _DriverActivityLogSummary({
    required this.title,
    required this.details,
  });
}

String _formatBusinessLocalDateTime(
  BuildContext context,
  BusinessLocalDateTime? value,
  String fallback,
) {
  if (value == null) return fallback;
  final material = MaterialLocalizations.of(context);
  final carrier = BusinessLocalDateTimeDateTimeAdapter.toDateTime(value);
  return '${material.formatShortDate(carrier)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(carrier))}';
}
