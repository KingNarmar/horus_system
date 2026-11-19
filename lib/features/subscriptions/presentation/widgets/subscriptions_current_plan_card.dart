import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_entitlement.dart';
import '../../domain/entities/entitlement_feature.dart';
import '../../domain/policies/entitlement_access_policy.dart';
import '../localization/subscriptions_localizations.dart';

/// Renders server-assigned features without granting any capability in the UI.
final class SubscriptionsCurrentPlanCard extends StatelessWidget {
  final CompanyEntitlement entitlement;

  const SubscriptionsCurrentPlanCard({required this.entitlement, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final theme = Theme.of(context);
    final planName = l10n.planName(entitlement.planCode, entitlement.planCode);
    final expiry = entitlement.expiresAt;
    final expiryLabel = expiry == null
        ? l10n.noExpiration
        : MaterialLocalizations.of(context).formatShortDate(expiry.toLocal());
    final now = DateTime.now().toUtc();
    final effective = EntitlementAccessPolicy.isEffective(entitlement, at: now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.subscriptions),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.currentPlan,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              planName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: l10n.status,
              value: l10n.entitlementStatusLabel(entitlement.status),
            ),
            _DetailRow(label: l10n.expiration, value: expiryLabel),
            if (!effective) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.entitlementInactiveNotice,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.planFeatures, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final feature in EntitlementFeature.values)
                  _FeatureChip(
                    label: l10n.featureLabel(feature),
                    enabled: EntitlementAccessPolicy.isFeatureEnabled(
                      entitlement,
                      feature,
                      at: now,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _FeatureChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _FeatureChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    return Chip(
      avatar: Icon(
        enabled ? AppIcons.reactivate : AppIcons.deactivate,
        size: AppSizes.iconSm,
      ),
      label: Text('$label (${enabled ? l10n.included : l10n.notIncluded})'),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
