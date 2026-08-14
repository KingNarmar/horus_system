import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../../../driver_finance/domain/entities/driver_finance_trip_option.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement_type.dart';
import '../../../driver_finance/presentation/localization/driver_finance_localizations_x.dart';
import '../../../driver_finance/presentation/widgets/driver_finance_details_section.dart';
import '../../domain/entities/driver.dart';
import '../cubit/drivers_state.dart';
import '../localization/drivers_localizations_x.dart';

const _driverFinancialMovementEntityKey = 'driver_financial_movement';
const _legacyDriverFinancialMovementEntityDisplayName =
    'Driver financial movement';
const _driverFinanceMovementAddedEvent = 'driver_finance_movement_added';

class DriverDetailsDialog extends StatelessWidget {
  final Driver driver;
  final DriversLoaded? state;
  final VoidCallback? onAddAdvance;
  final VoidCallback? onAddDriverCharge;
  final VoidCallback? onAddCashReturn;

  const DriverDetailsDialog({
    required this.driver,
    required this.state,
    this.onAddAdvance,
    this.onAddDriverCharge,
    this.onAddCashReturn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCompact =
        MediaQuery.sizeOf(context).width <= AppSizes.mobileMaxContentWidth;
    final isSelectedDriver = state?.selectedDriver?.id == driver.id;
    final activity = isSelectedDriver
        ? state!.selectedDriverActivity
        : const <AuditLog>[];
    final isLoading = isSelectedDriver && (state?.isActivityLoading ?? false);
    final failure = isSelectedDriver ? state?.activityFailure : null;
    final movements = isSelectedDriver
        ? state!.selectedDriverFinancialMovements
        : const <DriverFinancialMovement>[];
    final tripOptions = isSelectedDriver
        ? state!.selectedDriverTripOptions
        : const <DriverFinanceTripOption>[];
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      insetPadding: isCompact
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            )
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.detailsDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.driverDetailsTitle(driver.fullName),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailsSection(
                title: l10n.basicInfo,
                children: [
                  AdaptiveDetailRow(
                    label: l10n.driverNameLabel,
                    value: driver.fullName,
                  ),
                  AdaptiveDetailRow(
                    label: l10n.phoneLabel,
                    value: _optional(driver.phone, l10n),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.nationalIdLabel,
                    value: _optional(driver.nationalId, l10n),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.licenseNumberLabel,
                    value: _optional(driver.licenseNumber, l10n),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.licenseExpiryDateLabel,
                    value: driver.licenseExpiryDate == null
                        ? l10n.emptyValue
                        : _dateOnly(driver.licenseExpiryDate!),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.notesLabel,
                    value: _optional(driver.notes, l10n),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.statusHeader,
                    value: l10n.driverStatusLabel(driver.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.driverImagesSectionTitle,
                children: [
                  if (isSelectedDriver && (state?.isImageUrlsLoading ?? false))
                    Text(l10n.driverImagesLoading)
                  else if (isSelectedDriver && state?.imageUrlsFailure != null)
                    Text(l10n.localizedErrorMessage(state!.imageUrlsFailure!))
                  else
                    _DriverImagesGrid(
                      profileImageUrl: isSelectedDriver
                          ? state?.selectedDriverImageUrls.profileImageUrl
                          : null,
                      licenseImageUrl: isSelectedDriver
                          ? state?.selectedDriverImageUrls.licenseImageUrl
                          : null,
                      licenseBackImageUrl: isSelectedDriver
                          ? state?.selectedDriverImageUrls.licenseBackImageUrl
                          : null,
                      nationalIdImageUrl: isSelectedDriver
                          ? state?.selectedDriverImageUrls.nationalIdImageUrl
                          : null,
                      nationalIdBackImageUrl: isSelectedDriver
                          ? state
                                ?.selectedDriverImageUrls
                                .nationalIdBackImageUrl
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DriverFinanceDetailsSection(
                movements: movements,
                balance: isSelectedDriver ? state?.selectedDriverBalance : null,
                tripOptions: tripOptions,
                canManage: state?.canManageDriverFinance ?? false,
                isLoading:
                    isSelectedDriver &&
                    (state?.isFinancialMovementsLoading ?? false),
                isSaving:
                    isSelectedDriver &&
                    (state?.isSavingFinancialMovement ?? false),
                failure: isSelectedDriver
                    ? state?.financialMovementsFailure
                    : null,
                onAddAdvance: onAddAdvance,
                onAddDriverCharge: onAddDriverCharge,
                onAddCashReturn: onAddCashReturn,
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.accountability,
                children: [
                  AdaptiveDetailRow(
                    label: l10n.createdBy,
                    value: _actorName(createdLog, l10n),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.createdRole,
                    value: l10n.auditRoleDisplayLabel(createdLog?.actorRole),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.createdAt,
                    value: createdLog == null
                        ? l10n.notAvailable
                        : _formatDateTime(context, createdLog.createdAt),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.lastActivityBy,
                    value: _actorName(latestLog, l10n),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.lastActivityRole,
                    value: l10n.auditRoleDisplayLabel(latestLog?.actorRole),
                  ),
                  AdaptiveDetailRow(
                    label: l10n.lastActivityAt,
                    value: latestLog == null
                        ? l10n.notAvailable
                        : _formatDateTime(context, latestLog.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.activityTimeline,
                children: [
                  if (isLoading)
                    Text(l10n.loadingActivity)
                  else if (failure != null)
                    Text(l10n.localizedErrorMessage(failure))
                  else if (activity.isEmpty)
                    Text(l10n.noActivityFound)
                  else
                    ...activity.map(
                      (log) => _ActivityTimelineItem(
                        log: log,
                        tripOptions: tripOptions,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AuditLog? _findOldestAction(List<AuditLog> logs, String action) {
    for (final log in logs.reversed) {
      if (log.action.value == action) return log;
    }
    return null;
  }

  String _actorName(AuditLog? log, AppLocalizations l10n) {
    final name = log?.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log?.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.unknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? l10n.emptyValue
        : normalized;
  }
}

class _DriverImagesGrid extends StatelessWidget {
  final String? profileImageUrl;
  final String? licenseImageUrl;
  final String? licenseBackImageUrl;
  final String? nationalIdImageUrl;
  final String? nationalIdBackImageUrl;

  const _DriverImagesGrid({
    required this.profileImageUrl,
    required this.licenseImageUrl,
    required this.licenseBackImageUrl,
    required this.nationalIdImageUrl,
    required this.nationalIdBackImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppSizes.dataTableBreakpoint;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _DriverImagePreview(
              label: l10n.driverProfileImageLabel,
              imageUrl: profileImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverLicenseFrontImageLabel,
              imageUrl: licenseImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverLicenseBackImageLabel,
              imageUrl: licenseBackImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverNationalIdFrontImageLabel,
              imageUrl: nationalIdImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
            _DriverImagePreview(
              label: l10n.driverNationalIdBackImageLabel,
              imageUrl: nationalIdBackImageUrl,
              width: compact ? constraints.maxWidth : 180,
            ),
          ],
        );
      },
    );
  }
}

class _DriverImagePreview extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final double width;

  const _DriverImagePreview({
    required this.label,
    required this.imageUrl,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final normalizedUrl = imageUrl?.trim();
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: normalizedUrl == null || normalizedUrl.isEmpty
                  ? Center(child: Text(l10n.emptyValue))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        normalizedUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text(l10n.emptyValue));
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final AuditLog log;
  final List<DriverFinanceTripOption> tripOptions;

  const _ActivityTimelineItem({required this.log, required this.tripOptions});

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

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
