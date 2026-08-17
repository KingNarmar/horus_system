import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../../../driver_finance/domain/entities/driver_finance_trip_option.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement.dart';
import '../../../driver_finance/presentation/widgets/driver_finance_details_section.dart';
import '../../domain/entities/driver.dart';
import '../cubit/drivers_state.dart';
import '../localization/drivers_localizations_x.dart';
import 'driver_activity_timeline_item.dart';
import 'driver_details_section.dart';
import 'driver_images_grid.dart';

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
              DriverDetailsSection(
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
              DriverDetailsSection(
                title: l10n.driverImagesSectionTitle,
                children: [
                  if (isSelectedDriver && (state?.isImageUrlsLoading ?? false))
                    Text(l10n.driverImagesLoading)
                  else if (isSelectedDriver && state?.imageUrlsFailure != null)
                    Text(l10n.localizedErrorMessage(state!.imageUrlsFailure!))
                  else
                    DriverImagesGrid(
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
              DriverDetailsSection(
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
              DriverDetailsSection(
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
                      (log) => DriverActivityTimelineItem(
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

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
