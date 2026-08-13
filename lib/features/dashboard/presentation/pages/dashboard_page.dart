import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../helpers/dashboard_failure_message.dart';
import '../helpers/dashboard_formatters.dart';
import '../localization/dashboard_localizations.dart';
import '../widgets/dashboard_metrics_grid.dart';

final class DashboardPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const DashboardPage({required this.currentCompanyContext, super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

final class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.currentCompanyContext;
    final newContext = widget.currentCompanyContext;
    if (oldContext.companyId != newContext.companyId ||
        oldContext.role != newContext.role) {
      context.read<DashboardCubit>().load(newContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.dashboardL10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return _DashboardStateView(
              state: state,
              onRetry: () => context.read<DashboardCubit>().load(
                widget.currentCompanyContext,
              ),
            );
          },
        ),
      ],
    );
  }
}

final class _DashboardStateView extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onRetry;

  const _DashboardStateView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final strings = context.dashboardL10n;
    final currentState = state;

    return switch (currentState) {
      DashboardInitial() ||
      DashboardLoading() => _LoadingView(message: strings.loading),
      DashboardLoadFailure(:final failure) => _FailureView(
        message: dashboardFailureMessage(context, failure),
        onRetry: onRetry,
      ),
      DashboardLoaded(:final summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.businessDate(
              formatDashboardDate(
                summary.businessDate,
                Localizations.localeOf(context).toLanguageTag(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardMetricsGrid(summary: summary),
        ],
      ),
    };
  }
}

final class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(message),
        ],
      ),
    );
  }
}

final class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final strings = context.dashboardL10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ),
      ),
    );
  }
}
