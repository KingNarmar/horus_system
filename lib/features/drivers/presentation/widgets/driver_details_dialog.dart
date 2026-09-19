import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/business_local_date_time_date_time_adapter.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/localization/audit_display_localizations_x.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../cubit/driver_compensation_cubit.dart';
import '../cubit/driver_compensation_state.dart';
import '../cubit/drivers_state.dart';
import '../localization/drivers_localizations_x.dart';
import 'driver_activity_timeline_item.dart';
import 'driver_compensation_details_section.dart';
import 'driver_details_section.dart';
import 'driver_images_grid.dart';

class DriverDetailsDialog extends StatelessWidget {
  final Driver driver;
  final DriversLoaded? state;
  final bool showCompensation;
  final VoidCallback? onAddCompensationRevision;
  final ValueChanged<DriverCompensationRevision>? onEndCompensationRevision;
  final ValueChanged<DriverCompensationRevision>? onAttachCompensationContract;
  final ValueChanged<DriverCompensationRevision>? onOpenCompensationContract;

  const DriverDetailsDialog({
    required this.driver,
    required this.state,
    required this.showCompensation,
    this.onAddCompensationRevision,
    this.onEndCompensationRevision,
    this.onAttachCompensationContract,
    this.onOpenCompensationContract,
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
              if (showCompensation) ...[
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<DriverCompensationCubit, DriverCompensationState>(
                  builder: (context, compensationState) {
                    return DriverCompensationDetailsSection(
                      state: compensationState,
                      onAddRevision: onAddCompensationRevision ?? () {},
                      onEndRevision: onEndCompensationRevision ?? (_) {},
                      onAttachContract: onAttachCompensationContract ?? (_) {},
                      onOpenContract: onOpenCompensationContract ?? (_) {},
                    );
                  },
                ),
              ],
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
                        : _formatBusinessLocalDateTime(
                            context,
                            state?.activityTimestampFor(createdLog.id),
                            l10n.notAvailable,
                          ),
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
                        : _formatBusinessLocalDateTime(
                            context,
                            state?.activityTimestampFor(latestLog.id),
                            l10n.notAvailable,
                          ),
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
                        createdAt: state?.activityTimestampFor(log.id),
                        tripOptions: const [],
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

String _dateOnly(BusinessDate value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
