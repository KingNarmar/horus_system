import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../helpers/customer_datetime_formatter.dart';
import '../localization/customers_localizations_x.dart';

class CustomerActivityTimelineItem extends StatelessWidget {
  final AuditLog log;

  const CustomerActivityTimelineItem({required this.log, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const visibleKeys = [
      'name',
      'contact_person',
      'phone',
      'email',
      'tax_registration_number',
      'address',
      'city',
      'country',
      'credit_limit',
      'is_active',
    ];
    final changes = AuditChangeBuilder.buildChanges(
      log: log,
      visibleKeys: visibleKeys,
      fieldLabelBuilder: l10n.customerAuditFieldLabel,
      valueLabelBuilder: l10n.customerAuditValueLabel,
    );
    final actorName = log.actorDisplayName?.trim().isNotEmpty == true
        ? log.actorDisplayName!.trim()
        : (log.actorEmail?.trim().isNotEmpty == true ? log.actorEmail!.trim() : l10n.customerUnknownUser);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(AppIcons.auditHistory, size: AppSizes.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customerAuditActionLabel(log.action.value),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(l10n.auditTimelineHeader(actorName, l10n.customerAuditRoleLabel(log.actorRole), CustomerDateTimeFormatter.format(context, log.createdAt))),
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.customerChanges, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  ...changes.map((change) => Text(l10n.auditChangeLine(change.label, change.oldValue, change.newValue))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
