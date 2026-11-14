import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_quota_snapshot.dart';
import '../../domain/entities/company_quota_usage.dart';
import '../../domain/entities/entitlement_resource.dart';
import '../localization/subscriptions_localizations.dart';

/// Server-confirmed quota usage for #32, #355, #356 and #357. Full reporting is #360.
/// The complete company usage dashboard remains in #360.
final class SubscriptionsQuotaUsageCard extends StatelessWidget {
  final CompanyQuotaSnapshot quota;

  const SubscriptionsQuotaUsageCard({required this.quota, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.usageTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.usageDescription),
            const SizedBox(height: AppSpacing.md),
            _QuotaLine(
              label: l10n.users,
              usage: quota.usageFor(EntitlementResource.companyUsers),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.vehicles,
              usage: quota.usageFor(EntitlementResource.combinedVehicles),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.customers,
              usage: quota.usageFor(EntitlementResource.customers),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.drivers,
              usage: quota.usageFor(EntitlementResource.drivers),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.routes,
              usage: quota.usageFor(EntitlementResource.routes),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.lifetimeTrips,
              usage: quota.usageFor(EntitlementResource.lifetimeTrips),
              showRemaining: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.lifetimeInvoices,
              usage: quota.usageFor(EntitlementResource.lifetimeInvoices),
              showRemaining: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuotaLine(
              label: l10n.businessDocuments,
              usage: quota.usageFor(EntitlementResource.businessDocuments),
              showRemaining: true,
            ),
          ],
        ),
      ),
    );
  }
}

final class _QuotaLine extends StatelessWidget {
  final String label;
  final CompanyQuotaUsage usage;
  final bool showRemaining;

  const _QuotaLine({
    required this.label,
    required this.usage,
    this.showRemaining = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final limit = usage.limit.value;
    final count = l10n.usageCount(
      usage.used,
      limit == null ? l10n.unlimited : limit.toString(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(count),
          ],
        ),
        if (showRemaining && usage.remaining != null)
          Text(l10n.usageRemaining(usage.remaining!)),
        if (usage.isOverLimit)
          Text(
            l10n.usageOverCap,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
