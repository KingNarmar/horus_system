import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/company_subscription.dart';
import '../localization/subscriptions_localizations.dart';

final class SubscriptionsCurrentPlanCard extends StatelessWidget {
  final CompanySubscription? currentSubscription;

  const SubscriptionsCurrentPlanCard({
    required this.currentSubscription,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    final subscription = currentSubscription;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: subscription == null
            ? _EmptyCurrentPlan(l10n: l10n)
            : _CurrentPlanDetails(subscription: subscription, l10n: l10n),
      ),
    );
  }
}

final class _EmptyCurrentPlan extends StatelessWidget {
  final SubscriptionsLocalizations l10n;

  const _EmptyCurrentPlan({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(label: l10n.currentPlan),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.noCurrentSubscription),
      ],
    );
  }
}

final class _CurrentPlanDetails extends StatelessWidget {
  final CompanySubscription subscription;
  final SubscriptionsLocalizations l10n;

  const _CurrentPlanDetails({required this.subscription, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final planName = l10n.planName(
      subscription.plan.code,
      subscription.plan.name,
    );
    final period = _periodLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardTitle(label: l10n.currentPlan),
        const SizedBox(height: AppSpacing.md),
        Text(
          planName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailRow(
          label: l10n.status,
          value: l10n.statusLabel(subscription.status),
        ),
        if (subscription.trialEndsAt != null)
          _DetailRow(
            label: l10n.trialEndsAt,
            value: _formatDate(context, subscription.trialEndsAt!),
          ),
        if (period != null)
          _DetailRow(label: l10n.currentPeriod, value: period),
      ],
    );
  }

  String? _periodLabel(BuildContext context) {
    final start = subscription.currentPeriodStart;
    final end = subscription.currentPeriodEnd;
    if (start == null || end == null) return null;
    return l10n.periodRange(
      _formatDate(context, start),
      _formatDate(context, end),
    );
  }

  String _formatDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
  }
}

final class _CardTitle extends StatelessWidget {
  final String label;

  const _CardTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(AppIcons.subscriptions),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
