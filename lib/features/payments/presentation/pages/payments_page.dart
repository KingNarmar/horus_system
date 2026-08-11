import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../di/payments_dependencies.dart';
import '../cubit/payments_cubit.dart';
import '../cubit/payments_state.dart';
import '../cubit/register_payment_cubit.dart';
import '../helpers/payments_failure_message.dart';
import '../localization/payments_localizations.dart';
import '../widgets/payments_list.dart';
import '../widgets/register_payment_dialog.dart';

final class PaymentsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const PaymentsPage({required this.currentCompanyContext, super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

final class _PaymentsPageState extends State<PaymentsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentsCubit>().loadPayments(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant PaymentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.currentCompanyContext;
    final newContext = widget.currentCompanyContext;
    if (oldContext.companyId != newContext.companyId ||
        oldContext.role != newContext.role) {
      context.read<PaymentsCubit>().loadPayments(newContext);
    }
  }

  Future<void> _openRegisterPayment() async {
    final registered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider<RegisterPaymentCubit>(
        create: (_) =>
            PaymentsDependencies.createRegisterPaymentCubit()
              ..load(widget.currentCompanyContext),
        child: const RegisterPaymentDialog(),
      ),
    );

    if (registered != true || !mounted) return;

    await context.read<PaymentsCubit>().refresh();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.paymentsL10n.paymentRegistered)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;

    return BlocBuilder<PaymentsCubit, PaymentsState>(
      builder: (context, state) {
        final loaded = state is PaymentsLoaded ? state : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  strings.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                );
                final registerButton = loaded?.canRegisterPayments == true
                    ? FilledButton.icon(
                        key: const ValueKey('registerPaymentButton'),
                        onPressed: _openRegisterPayment,
                        icon: const Icon(AppIcons.add),
                        label: Text(strings.registerPayment),
                      )
                    : null;

                if (constraints.maxWidth < AppSizes.detailsStackBreakpoint) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      if (registerButton != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        registerButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: title),
                    ?registerButton,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _PaymentsStateView(
              state: state,
              onRetry: () => context.read<PaymentsCubit>().loadPayments(
                widget.currentCompanyContext,
              ),
              onSearchChanged: context.read<PaymentsCubit>().setSearchQuery,
            ),
          ],
        );
      },
    );
  }
}

final class _PaymentsStateView extends StatelessWidget {
  final PaymentsState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearchChanged;

  const _PaymentsStateView({
    required this.state,
    required this.onRetry,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;
    final currentState = state;

    return switch (currentState) {
      PaymentsInitial() || PaymentsLoading() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(strings.loading),
          ],
        ),
      ),
      PaymentsFailure(:final failure) => _FailureView(
        message: paymentsFailureMessage(context, failure),
        onRetry: onRetry,
      ),
      PaymentsLoaded() => _LoadedPaymentsView(
        state: currentState,
        onSearchChanged: onSearchChanged,
      ),
    };
  }
}

final class _LoadedPaymentsView extends StatelessWidget {
  final PaymentsLoaded state;
  final ValueChanged<String> onSearchChanged;

  const _LoadedPaymentsView({
    required this.state,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;
    final fractionDigits =
        state.currentCompanyContext.company.baseCurrencyFractionDigits;

    if (fractionDigits == null) {
      return Text(strings.regionalSettingsFailure);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.searchFieldMaxWidth,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.search),
              hintText: strings.searchHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PaymentsList(state: state, fractionDigits: fractionDigits),
      ],
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
            child: Text(context.paymentsL10n.retry),
          ),
        ],
      ),
    );
  }
}
