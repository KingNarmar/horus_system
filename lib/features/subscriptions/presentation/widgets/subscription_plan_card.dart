import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/plan_limit.dart';
import '../../domain/entities/subscription_plan.dart';
import '../localization/subscriptions_localizations.dart';

final class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;

  const SubscriptionPlanCard({required this.plan, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final planName = l10n.planName(plan.code, plan.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(AppIcons.subscriptions),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_priceLabel(l10n)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(label: l10n.planLimits),
            const SizedBox(height: AppSpacing.sm),
            _LimitRow(label: l10n.users, limit: plan.maxUsers),
            _LimitRow(label: l10n.vehicles, limit: plan.maxVehicles),
            _LimitRow(label: l10n.tripsPerMonth, limit: plan.maxTripsPerMonth),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle(label: l10n.planFeatures),
            const SizedBox(height: AppSpacing.sm),
            _FeatureRow(label: l10n.driverApp, included: plan.hasDriverApp),
            _FeatureRow(
              label: l10n.advancedReports,
              included: plan.hasAdvancedReports,
            ),
            _FeatureRow(
              label: l10n.documentUpload,
              included: plan.hasDocumentUpload,
            ),
            _FeatureRow(label: l10n.maintenance, included: plan.hasMaintenance),
            _FeatureRow(
              label: l10n.whatsappNotifications,
              included: plan.hasWhatsappNotifications,
            ),
          ],
        ),
      ),
    );
  }

  String _priceLabel(SubscriptionsLocalizations l10n) {
    if (plan.monthlyPrice == 0) return l10n.pricePerMonth(l10n.free);
    return l10n.pricePerMonth(plan.monthlyPrice.toStringAsFixed(0));
  }
}

final class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

final class _LimitRow extends StatelessWidget {
  final String label;
  final PlanLimit limit;

  const _LimitRow({required this.label, required this.limit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final value = limit.isUnlimited
        ? l10n.unlimited
        : l10n.limitValue(limit.value!);

    return _DetailRow(label: label, value: value);
  }
}

final class _FeatureRow extends StatelessWidget {
  final String label;
  final bool included;

  const _FeatureRow({required this.label, required this.included});

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    return _DetailRow(
      label: label,
      value: included ? l10n.included : l10n.notIncluded,
      icon: included ? AppIcons.reactivate : AppIcons.deactivate,
    );
  }
}

final class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _DetailRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
          ],
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
