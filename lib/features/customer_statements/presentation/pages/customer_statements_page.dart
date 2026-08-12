import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../cubit/customer_statements_cubit.dart';
import '../cubit/customer_statements_state.dart';
import '../helpers/customer_statements_failure_message.dart';
import '../localization/customer_statements_localizations.dart';
import '../widgets/customer_statement_filters.dart';
import '../widgets/customer_statement_movements.dart';
import '../widgets/customer_statement_summary.dart';

final class CustomerStatementsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CustomerStatementsPage({
    required this.currentCompanyContext,
    super.key,
  });

  @override
  State<CustomerStatementsPage> createState() => _CustomerStatementsPageState();
}

final class _CustomerStatementsPageState extends State<CustomerStatementsPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerStatementsCubit>().load(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant CustomerStatementsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.currentCompanyContext;
    final newContext = widget.currentCompanyContext;
    if (oldContext.companyId != newContext.companyId ||
        oldContext.role != newContext.role) {
      context.read<CustomerStatementsCubit>().load(newContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;

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
        BlocBuilder<CustomerStatementsCubit, CustomerStatementsState>(
          builder: (context, state) {
            return _CustomerStatementsStateView(
              state: state,
              onRetry: () => context.read<CustomerStatementsCubit>().load(
                widget.currentCompanyContext,
              ),
            );
          },
        ),
      ],
    );
  }
}

final class _CustomerStatementsStateView extends StatelessWidget {
  final CustomerStatementsState state;
  final VoidCallback onRetry;

  const _CustomerStatementsStateView({
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;

    final currentState = state;

    return switch (currentState) {
      CustomerStatementsInitial() ||
      CustomerStatementsLoadingCustomers() => _LoadingView(
        message: strings.loadingCustomers,
      ),
      CustomerStatementsLoadFailure(:final failure) => _FailureView(
        message: customerStatementsFailureMessage(context, failure),
        onRetry: onRetry,
      ),
      CustomerStatementsReady() => _ReadyView(state: currentState),
    };
  }
}

final class _ReadyView extends StatelessWidget {
  final CustomerStatementsReady state;

  const _ReadyView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerStatementsCubit>();
    final strings = context.customerStatementsL10n;

    if (state.customers.isEmpty) {
      return Text(strings.noCustomers);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomerStatementFilters(
          customers: state.customers,
          selectedCustomerId: state.selectedCustomerId,
          fromDate: state.fromDate,
          toDate: state.toDate,
          canApply: state.canApply,
          onCustomerChanged: cubit.selectCustomer,
          onFromDateChanged: cubit.setFromDate,
          onToDateChanged: cubit.setToDate,
          onApply: cubit.apply,
          onClearDates: cubit.clearDates,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.isLoadingStatement)
          _LoadingView(message: strings.loadingStatement)
        else if (state.statementFailure != null)
          _FailureView(
            message: customerStatementsFailureMessage(
              context,
              state.statementFailure!,
            ),
            onRetry: cubit.apply,
          )
        else if (state.statement != null) ...[
          CustomerStatementSummary(statement: state.statement!),
          const SizedBox(height: AppSpacing.lg),
          CustomerStatementMovements(statement: state.statement!),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: Text(strings.selectCustomerPrompt)),
          ),
      ],
    );
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
          const SizedBox(height: AppSpacing.md),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.customerStatementsL10n.retry),
          ),
        ],
      ),
    );
  }
}
