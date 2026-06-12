import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';
import '../cubit/customers_state.dart';
import 'customers_cards.dart';
import 'customers_filters.dart';
import 'customers_table.dart';
import 'empty_customers_message.dart';

class CustomersStateView extends StatelessWidget {
  final CustomersState state;
  final VoidCallback onRetry;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusFilterChanged;

  const CustomersStateView({
    required this.state,
    required this.onRetry,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentState = state;

    if (currentState is CustomersInitial || currentState is CustomersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentState is CustomersFailure) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Text(
                l10n.localizedErrorMessage(currentState.failure),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }

    if (currentState is! CustomersLoaded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomersFilters(
          statusFilter: currentState.statusFilter,
          onSearchChanged: onSearchChanged,
          onStatusFilterChanged: onStatusFilterChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (currentState.allCustomers.isEmpty)
          EmptyCustomersMessage(message: l10n.noCustomersFound)
        else if (currentState.customers.isEmpty)
          EmptyCustomersMessage(message: l10n.noCustomersMatchFilters)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
                return CustomersTable(
                  customers: currentState.customers,
                  canManageCustomers: currentState.canManageCustomers,
                  onViewDetails: onViewDetails,
                  onEdit: onEdit,
                  onDeactivate: onDeactivate,
                  onReactivate: onReactivate,
                );
              }
              return CustomersCards(
                customers: currentState.customers,
                canManageCustomers: currentState.canManageCustomers,
                onViewDetails: onViewDetails,
                onEdit: onEdit,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              );
            },
          ),
      ],
    );
  }
}
