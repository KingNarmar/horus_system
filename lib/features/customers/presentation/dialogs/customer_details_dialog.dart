import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/customer.dart';
import '../cubit/customers_state.dart';
import '../helpers/customer_datetime_formatter.dart';
import '../localization/customers_localizations_x.dart';
import 'customer_activity_timeline_item.dart';
import 'customer_detail_row.dart';
import 'customer_details_section.dart';

class CustomerDetailsDialog extends StatelessWidget {
  final Customer customer;
  final CustomersLoaded? state;

  const CustomerDetailsDialog({
    required this.customer,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activity = state?.selectedCustomer?.id == customer.id
        ? state!.selectedCustomerActivity
        : const <AuditLog>[];
    final isLoading =
        state?.selectedCustomer?.id == customer.id &&
        (state?.isActivityLoading ?? false);
    final failure = state?.selectedCustomer?.id == customer.id
        ? state?.activityFailure
        : null;
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.detailsDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.customerDetailsTitle(customer.name),
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
              CustomerDetailsSection(
                title: l10n.customerBasicInfo,
                children: [
                  CustomerDetailRow(
                    label: l10n.customerNameLabel,
                    value: customer.name,
                  ),
                  CustomerDetailRow(
                    label: l10n.contactPersonLabel,
                    value: _optional(customer.contactPerson, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.phoneLabel,
                    value: _optional(customer.phone, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.emailLabel,
                    value: _optional(customer.email, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.addressLabel,
                    value: _optional(customer.address, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.cityLabel,
                    value: _optional(customer.city, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.countryLabel,
                    value: _optional(customer.country, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.taxRegistrationNumberLabel,
                    value: _optional(customer.taxRegistrationNumber, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.creditLimitLabel,
                    value:
                        customer.creditLimit?.toStringAsFixed(2) ??
                        l10n.customerEmptyValue,
                  ),
                  CustomerDetailRow(
                    label: l10n.statusHeader,
                    value: customer.isActive
                        ? l10n.activeStatus
                        : l10n.inactiveStatus,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomerDetailsSection(
                title: l10n.customerAccountability,
                children: [
                  CustomerDetailRow(
                    label: l10n.customerCreatedBy,
                    value: _actorName(createdLog, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.customerCreatedRole,
                    value: l10n.customerAuditRoleLabel(createdLog?.actorRole),
                  ),
                  CustomerDetailRow(
                    label: l10n.customerCreatedAt,
                    value: createdLog == null
                        ? l10n.customerNotAvailable
                        : CustomerDateTimeFormatter.format(
                            context,
                            createdLog.createdAt,
                          ),
                  ),
                  CustomerDetailRow(
                    label: l10n.customerLastActivityBy,
                    value: _actorName(latestLog, l10n),
                  ),
                  CustomerDetailRow(
                    label: l10n.customerLastActivityRole,
                    value: l10n.customerAuditRoleLabel(latestLog?.actorRole),
                  ),
                  CustomerDetailRow(
                    label: l10n.customerLastActivityAt,
                    value: latestLog == null
                        ? l10n.customerNotAvailable
                        : CustomerDateTimeFormatter.format(
                            context,
                            latestLog.createdAt,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomerDetailsSection(
                title: l10n.customerActivityTimeline,
                children: [
                  if (isLoading)
                    Row(
                      children: [
                        const SizedBox(
                          height: AppSizes.iconSm,
                          width: AppSizes.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.customerLoadingActivity),
                      ],
                    )
                  else if (failure != null)
                    Text(l10n.localizedErrorMessage(failure))
                  else if (activity.isEmpty)
                    Text(l10n.customerNoActivityFound)
                  else
                    ...activity.map(
                      (log) => CustomerActivityTimelineItem(log: log),
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
    return l10n.customerUnknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? l10n.customerEmptyValue
        : normalized;
  }
}
