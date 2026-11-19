import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_quota_snapshot.dart';
import '../../domain/entities/company_quota_usage.dart';
import '../../domain/entities/entitlement_resource.dart';
import '../../domain/policies/quota_usage_display_policy.dart';
import '../localization/subscriptions_localizations.dart';

/// Displays the authoritative server counters; never calculates quotas locally.
final class SubscriptionsQuotaUsageCard extends StatelessWidget {
  final CompanyQuotaSnapshot quota;

  const SubscriptionsQuotaUsageCard({required this.quota, super.key});

  static const _resources = <EntitlementResource>[
    EntitlementResource.companyUsers,
    EntitlementResource.combinedVehicles,
    EntitlementResource.customers,
    EntitlementResource.drivers,
    EntitlementResource.routes,
    EntitlementResource.lifetimeTrips,
    EntitlementResource.lifetimeInvoices,
    EntitlementResource.businessDocuments,
  ];

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
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    constraints.maxWidth >= AppSizes.dataTableBreakpoint;
                final itemWidth = twoColumns
                    ? (constraints.maxWidth - AppSpacing.md) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final resource in _resources)
                      SizedBox(
                        width: itemWidth,
                        child: _QuotaUsageItem(
                          label: l10n.resourceLabel(resource),
                          usage: quota.usageFor(resource),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.usageOutputsUnaffected,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _QuotaUsageItem extends StatelessWidget {
  final String label;
  final CompanyQuotaUsage usage;

  const _QuotaUsageItem({required this.label, required this.usage});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final theme = Theme.of(context);
    final level = QuotaUsageDisplayPolicy.levelFor(usage);
    final limit = usage.limit.value;
    final count = l10n.usageCount(
      usage.used,
      limit == null ? l10n.unlimited : limit.toString(),
    );
    final color = switch (level) {
      QuotaUsageLevel.atLimit ||
      QuotaUsageLevel.overLimit => theme.colorScheme.error,
      QuotaUsageLevel.nearLimit => theme.colorScheme.tertiary,
      QuotaUsageLevel.normal || QuotaUsageLevel.unlimited => null,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(count),
            if (level != QuotaUsageLevel.unlimited) ...[
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: QuotaUsageDisplayPolicy.progressFor(usage),
                color: color,
                semanticsLabel: label,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.quotaLevelLabel(level),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
            if (usage.remaining != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.usageRemaining(usage.remaining!),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
