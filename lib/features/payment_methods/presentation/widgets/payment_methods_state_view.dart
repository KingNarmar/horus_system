import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_status_filter.dart';
import '../cubit/payment_methods_state.dart';
import '../helpers/payment_methods_failure_message.dart';
import '../localization/payment_methods_localizations.dart';

class PaymentMethodsStateView extends StatelessWidget {
  final PaymentMethodsState state;
  final VoidCallback onRetry;
  final ValueChanged<PaymentMethodStatusFilter> onStatusFilterChanged;
  final ValueChanged<PaymentMethod> onEdit;
  final ValueChanged<PaymentMethod> onDeactivate;
  final ValueChanged<PaymentMethod> onReactivate;

  const PaymentMethodsStateView({
    required this.state,
    required this.onRetry,
    required this.onStatusFilterChanged,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    return switch (state) {
      PaymentMethodsInitial() || PaymentMethodsLoading() => _Loading(l10n: l10n),
      PaymentMethodsFailure(:final failure) => _Failure(
        message: paymentMethodsFailureMessage(failure, l10n),
        onRetry: onRetry,
        l10n: l10n,
      ),
      PaymentMethodsLoaded() => _Loaded(
        state: state as PaymentMethodsLoaded,
        onStatusFilterChanged: onStatusFilterChanged,
        onEdit: onEdit,
        onDeactivate: onDeactivate,
        onReactivate: onReactivate,
      ),
    };
  }
}

class _Loading extends StatelessWidget {
  final PaymentMethodsLocalizations l10n;

  const _Loading({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.loading),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final PaymentMethodsLocalizations l10n;

  const _Failure({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  final PaymentMethodsLoaded state;
  final ValueChanged<PaymentMethodStatusFilter> onStatusFilterChanged;
  final ValueChanged<PaymentMethod> onEdit;
  final ValueChanged<PaymentMethod> onDeactivate;
  final ValueChanged<PaymentMethod> onReactivate;

  const _Loaded({
    required this.state,
    required this.onStatusFilterChanged,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    final methods = state.visibleMethods;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: PaymentMethodStatusFilter.values
              .map(
                (filter) => FilterChip(
                  label: Text(_filterLabel(filter, l10n)),
                  selected: state.statusFilter == filter,
                  onSelected: (_) => onStatusFilterChanged(filter),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (methods.isEmpty)
          Text(state.allMethods.isEmpty ? l10n.noMethods : l10n.noFilteredMethods)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
                return _MethodsTable(
                  methods: methods,
                  state: state,
                  onEdit: onEdit,
                  onDeactivate: onDeactivate,
                  onReactivate: onReactivate,
                );
              }
              return _MethodsCards(
                methods: methods,
                state: state,
                onEdit: onEdit,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              );
            },
          ),
      ],
    );
  }

  String _filterLabel(
    PaymentMethodStatusFilter filter,
    PaymentMethodsLocalizations l10n,
  ) {
    return switch (filter) {
      PaymentMethodStatusFilter.active => l10n.active,
      PaymentMethodStatusFilter.inactive => l10n.inactive,
      PaymentMethodStatusFilter.all => l10n.all,
    };
  }
}

class _MethodsTable extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethodsLoaded state;
  final ValueChanged<PaymentMethod> onEdit;
  final ValueChanged<PaymentMethod> onDeactivate;
  final ValueChanged<PaymentMethod> onReactivate;

  const _MethodsTable({
    required this.methods,
    required this.state,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.nameLabel)),
          DataColumn(label: Text(l10n.status)),
          if (state.canManagePaymentMethods)
            DataColumn(label: Text(l10n.actions)),
        ],
        rows: methods
            .map(
              (method) => DataRow(
                cells: [
                  DataCell(Text(method.name)),
                  DataCell(Chip(label: Text(method.isActive ? l10n.active : l10n.inactive))),
                  if (state.canManagePaymentMethods)
                    DataCell(
                      _MethodActions(
                        method: method,
                        state: state,
                        onEdit: onEdit,
                        onDeactivate: onDeactivate,
                        onReactivate: onReactivate,
                      ),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MethodsCards extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethodsLoaded state;
  final ValueChanged<PaymentMethod> onEdit;
  final ValueChanged<PaymentMethod> onDeactivate;
  final ValueChanged<PaymentMethod> onReactivate;

  const _MethodsCards({
    required this.methods,
    required this.state,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    return Column(
      children: methods
          .map(
            (method) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(method.isActive ? l10n.active : l10n.inactive),
                          ],
                        ),
                      ),
                      if (state.canManagePaymentMethods)
                        _MethodActions(
                          method: method,
                          state: state,
                          onEdit: onEdit,
                          onDeactivate: onDeactivate,
                          onReactivate: onReactivate,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MethodActions extends StatelessWidget {
  final PaymentMethod method;
  final PaymentMethodsLoaded state;
  final ValueChanged<PaymentMethod> onEdit;
  final ValueChanged<PaymentMethod> onDeactivate;
  final ValueChanged<PaymentMethod> onReactivate;

  const _MethodActions({
    required this.method,
    required this.state,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.paymentMethodsL10n;
    final isPending = state.pendingActionPaymentMethodId == method.id;
    final statusActionBlocked = state.pendingActionPaymentMethodId != null;

    if (isPending) {
      return const SizedBox(
        width: AppSizes.loadingIndicatorSm,
        height: AppSizes.loadingIndicatorSm,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.edit,
          onPressed: state.isSubmitting ? null : () => onEdit(method),
          icon: const Icon(AppIcons.edit),
        ),
        IconButton(
          tooltip: method.isActive ? l10n.deactivate : l10n.reactivate,
          onPressed: statusActionBlocked || state.isSubmitting
              ? null
              : () => method.isActive
                    ? onDeactivate(method)
                    : onReactivate(method),
          icon: Icon(method.isActive ? AppIcons.deactivate : AppIcons.reactivate),
        ),
      ],
    );
  }
}
