import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/payment_method.dart';
import '../cubit/payment_methods_cubit.dart';
import '../cubit/payment_methods_state.dart';
import '../helpers/payment_methods_failure_message.dart';
import '../localization/payment_methods_localizations.dart';
import '../widgets/payment_method_form_dialog.dart';
import '../widgets/payment_methods_state_view.dart';

class PaymentMethodsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const PaymentMethodsPage({required this.currentCompanyContext, super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentMethodsCubit>().loadPaymentMethods(
      widget.currentCompanyContext,
    );
  }

  @override
  void didUpdateWidget(covariant PaymentMethodsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCompanyContext.companyId !=
            widget.currentCompanyContext.companyId ||
        oldWidget.currentCompanyContext.role !=
            widget.currentCompanyContext.role) {
      context.read<PaymentMethodsCubit>().loadPaymentMethods(
        widget.currentCompanyContext,
      );
    }
  }

  Future<void> _openForm({PaymentMethod? paymentMethod}) async {
    final cubit = context.read<PaymentMethodsCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => PaymentMethodFormDialog(
        paymentMethod: paymentMethod,
        onSubmit: (name) {
          if (paymentMethod == null) {
            return cubit.addPaymentMethod(name);
          }
          return cubit.updatePaymentMethod(
            paymentMethod: paymentMethod,
            name: name,
          );
        },
      ),
    );
  }

  Future<void> _deactivate(PaymentMethod paymentMethod) async {
    final l10n = context.paymentMethodsL10n;
    final confirmed = await _confirm(
      title: l10n.confirmDeactivateTitle,
      body: l10n.confirmDeactivateBody,
      confirmLabel: l10n.deactivate,
    );
    if (confirmed && mounted) {
      await context.read<PaymentMethodsCubit>().deactivatePaymentMethod(
        paymentMethod,
      );
    }
  }

  Future<void> _reactivate(PaymentMethod paymentMethod) async {
    final l10n = context.paymentMethodsL10n;
    final confirmed = await _confirm(
      title: l10n.confirmReactivateTitle,
      body: l10n.confirmReactivateBody,
      confirmLabel: l10n.reactivate,
    );
    if (confirmed && mounted) {
      await context.read<PaymentMethodsCubit>().reactivatePaymentMethod(
        paymentMethod,
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final l10n = context.paymentMethodsL10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showFeedback(PaymentMethodsLoaded state) {
    final l10n = context.paymentMethodsL10n;
    final message = state.mutationFailure != null
        ? paymentMethodsFailureMessage(state.mutationFailure!, l10n)
        : switch (state.completedMutation) {
            PaymentMethodMutation.created => l10n.createdSuccess,
            PaymentMethodMutation.updated => l10n.updatedSuccess,
            PaymentMethodMutation.deactivated => l10n.deactivatedSuccess,
            PaymentMethodMutation.reactivated => l10n.reactivatedSuccess,
            null => null,
          };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentMethodsCubit, PaymentMethodsState>(
      listenWhen: (previous, current) {
        if (current is! PaymentMethodsLoaded) return false;
        final previousSequence = previous is PaymentMethodsLoaded
            ? previous.feedbackSequence
            : -1;
        return current.feedbackSequence != previousSequence &&
            current.feedbackSequence > 0;
      },
      listener: (context, state) {
        if (state is PaymentMethodsLoaded) _showFeedback(state);
      },
      builder: (context, state) {
        final cubit = context.read<PaymentMethodsCubit>();
        final loadedState = state is PaymentMethodsLoaded ? state : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(
              canManage: loadedState?.canManagePaymentMethods ?? false,
              isBusy: loadedState?.isMutationPending ?? false,
              onAdd: _openForm,
            ),
            const SizedBox(height: AppSpacing.lg),
            PaymentMethodsStateView(
              state: state,
              onRetry: () =>
                  cubit.loadPaymentMethods(widget.currentCompanyContext),
              onStatusFilterChanged: cubit.setStatusFilter,
              onEdit: (method) => _openForm(paymentMethod: method),
              onDeactivate: _deactivate,
              onReactivate: _reactivate,
            ),
          ],
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool canManage;
  final bool isBusy;
  final VoidCallback onAdd;

  const _PageHeader({
    required this.canManage,
    required this.isBusy,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    final addButton = FilledButton.icon(
      onPressed: isBusy ? null : onAdd,
      icon: const Icon(AppIcons.add),
      label: Text(l10n.addMethod),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeader =
            constraints.maxWidth < AppSizes.detailsStackBreakpoint;
        if (stackHeader) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderText(),
              if (canManage) ...[
                const SizedBox(height: AppSpacing.md),
                addButton,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _HeaderText()),
            if (canManage) ...[const SizedBox(width: AppSpacing.md), addButton],
          ],
        );
      },
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText();

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.description),
      ],
    );
  }
}
