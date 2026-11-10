import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../helpers/subscriptions_failure_message.dart';
import '../localization/subscriptions_localizations.dart';
import '../widgets/subscriptions_current_plan_card.dart';

final class SubscriptionsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const SubscriptionsPage({required this.currentCompanyContext, super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

final class _SubscriptionsPageState extends State<SubscriptionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionsCubit>().load(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant SubscriptionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCompanyContext.companyId !=
            widget.currentCompanyContext.companyId ||
        oldWidget.currentCompanyContext.role !=
            widget.currentCompanyContext.role) {
      context.read<SubscriptionsCubit>().load(widget.currentCompanyContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.subscriptionsL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(l10n: l10n),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
          builder: (context, state) {
            return switch (state) {
              SubscriptionsInitial() ||
              SubscriptionsLoading() => _LoadingState(l10n: l10n),
              SubscriptionsFailure(:final failure) => _FailureState(
                message: subscriptionsFailureMessage(failure, l10n),
                onRetry: () => context.read<SubscriptionsCubit>().load(
                  widget.currentCompanyContext,
                ),
                l10n: l10n,
              ),
              SubscriptionsLoaded() => _LoadedState(state: state),
            };
          },
        ),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  final SubscriptionsLocalizations l10n;

  const _Header({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.subscriptions),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.description),
      ],
    );
  }
}

final class _LoadingState extends StatelessWidget {
  final SubscriptionsLocalizations l10n;

  const _LoadingState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            const SizedBox(
              width: AppSizes.loadingIndicatorSm,
              height: AppSizes.loadingIndicatorSm,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(l10n.loading)),
          ],
        ),
      ),
    );
  }
}

final class _FailureState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final SubscriptionsLocalizations l10n;

  const _FailureState({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(AppIcons.reactivate),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// V1 displays the assigned plan, not historical placeholder sales offers.
/// Effective quota usage is rendered through the canonical service in #360.
final class _LoadedState extends StatelessWidget {
  final SubscriptionsLoaded state;

  const _LoadedState({required this.state});

  @override
  Widget build(BuildContext context) {
    return SubscriptionsCurrentPlanCard(entitlement: state.entitlement);
  }
}
