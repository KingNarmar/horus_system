import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_entitlement.dart';
import '../localization/subscriptions_localizations.dart';

/// Renders the effective server-authoritative entitlement, not billing data.
final class SubscriptionsCurrentPlanCard extends StatelessWidget {
  final CompanyEntitlement entitlement;

  const SubscriptionsCurrentPlanCard({
    required this.entitlement,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final planName = l10n.planName(
      entitlement.planCode,
      entitlement.planCode,
    );
    final expiry = entitlement.expiresAt;
    final expiryLabel = expiry == null
        ? l10n.noExpiration
        : MaterialLocalizations.of(context).formatShortDate(expiry.toLocal());

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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              planName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: l10n.status,
              value: l10n.entitlementStatusLabel(entitlement.status),
            ),
            _DetailRow(label: l10n.expiration, value: expiryLabel),
          ],
        ),
      ),
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
