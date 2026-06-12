import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../widgets/customer_form_dialog.dart';

class CustomersPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const CustomersPage({required this.currentCompanyContext, super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  void initState() {
    super.initState();
    context.read<CustomersCubit>().loadCustomers(widget.currentCompanyContext);
  }

  Future<void> _openCustomerForm({Customer? customer}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CustomerFormDialog(
        customer: customer,
        onSubmit: (data) {
          final cubit = context.read<CustomersCubit>();

          if (customer == null) {
            return cubit.addCustomer(
              name: data.name,
              contactPerson: data.contactPerson,
              phone: data.phone,
              email: data.email,
              taxRegistrationNumber: data.taxRegistrationNumber,
              address: data.address,
              city: data.city,
              country: data.country,
              creditLimit: data.creditLimit,
            );
          }

          return cubit.updateCustomer(
            customer: customer,
            name: data.name,
            contactPerson: data.contactPerson,
            phone: data.phone,
            email: data.email,
            taxRegistrationNumber: data.taxRegistrationNumber,
            address: data.address,
            city: data.city,
            country: data.country,
            creditLimit: data.creditLimit,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        final cubit = context.read<CustomersCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.customersTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (state is CustomersLoaded && state.canManageCustomers)
                  FilledButton.icon(
                    onPressed: () => _openCustomerForm(),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addCustomerButton),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _CustomersStateView(
              state: state,
              onRetry: () => cubit.loadCustomers(widget.currentCompanyContext),
              onEdit: (customer) => _openCustomerForm(customer: customer),
              onDeactivate: cubit.deactivateCustomer,
              onReactivate: cubit.reactivateCustomer,
              onSearchChanged: cubit.setSearchQuery,
              onStatusFilterChanged: cubit.setStatusFilter,
            ),
          ],
        );
      },
    );
  }
}

class _CustomersStateView extends StatelessWidget {
  static const double _tableBreakpoint = 760;

  final CustomersState state;
  final VoidCallback onRetry;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusFilterChanged;

  const _CustomersStateView({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
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
              Text(currentState.failure.message, textAlign: TextAlign.center),
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
        _CustomersFilters(
          statusFilter: currentState.statusFilter,
          onSearchChanged: onSearchChanged,
          onStatusFilterChanged: onStatusFilterChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (currentState.allCustomers.isEmpty)
          _EmptyCustomersMessage(message: l10n.noCustomersFound)
        else if (currentState.customers.isEmpty)
          _EmptyCustomersMessage(message: l10n.noCustomersMatchFilters)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldUseTable = constraints.maxWidth >= _tableBreakpoint;

              if (shouldUseTable) {
                return _CustomersTable(
                  customers: currentState.customers,
                  canManageCustomers: currentState.canManageCustomers,
                  onEdit: onEdit,
                  onDeactivate: onDeactivate,
                  onReactivate: onReactivate,
                );
              }

              return _CustomersCards(
                customers: currentState.customers,
                canManageCustomers: currentState.canManageCustomers,
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

class _CustomersFilters extends StatelessWidget {
  final CustomerStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusFilterChanged;

  const _CustomersFilters({
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchCustomersHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<CustomerStatusFilter>(
          segments: [
            ButtonSegment(
              value: CustomerStatusFilter.all,
              label: Text(l10n.customersStatusAllFilter),
            ),
            ButtonSegment(
              value: CustomerStatusFilter.active,
              label: Text(l10n.customersStatusActiveFilter),
            ),
            ButtonSegment(
              value: CustomerStatusFilter.inactive,
              label: Text(l10n.customersStatusInactiveFilter),
            ),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) =>
              onStatusFilterChanged(selected.first),
        ),
      ],
    );
  }
}

class _EmptyCustomersMessage extends StatelessWidget {
  final String message;

  const _EmptyCustomersMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _CustomersCards extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const _CustomersCards({
    required this.customers,
    required this.canManageCustomers,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: customers
          .map(
            (customer) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CustomerCard(
                customer: customer,
                canManageCustomers: canManageCustomers,
                onEdit: onEdit,
                onDeactivate: onDeactivate,
                onReactivate: onReactivate,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool canManageCustomers;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const _CustomerCard({
    required this.customer,
    required this.canManageCustomers,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (customer.contactPerson != null)
              Text(l10n.contactPersonLine(customer.contactPerson!)),
            if (customer.phone != null) Text(l10n.phoneLine(customer.phone!)),
            if (customer.email != null) Text(l10n.emailLine(customer.email!)),
            if (customer.city != null) Text(l10n.cityLine(customer.city!)),
            Text(
              l10n.statusLine(
                customer.isActive ? l10n.activeStatus : l10n.inactiveStatus,
              ),
            ),
            if (canManageCustomers) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onEdit(customer),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.editCustomerButton),
                  ),
                  if (customer.isActive)
                    OutlinedButton.icon(
                      onPressed: () => onDeactivate(customer),
                      icon: const Icon(Icons.block_outlined),
                      label: Text(l10n.deactivateCustomerButton),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => onReactivate(customer),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.reactivateCustomerButton),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const _CustomersTable({
    required this.customers,
    required this.canManageCustomers,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: AppSizes.desktopMinWidth),
          child: DataTable(
            columns: [
              DataColumn(label: Text(l10n.customerNameHeader)),
              DataColumn(label: Text(l10n.contactHeader)),
              DataColumn(label: Text(l10n.phoneLabel)),
              DataColumn(label: Text(l10n.emailLabel)),
              DataColumn(label: Text(l10n.cityLabel)),
              DataColumn(label: Text(l10n.statusHeader)),
              if (canManageCustomers)
                DataColumn(label: Text(l10n.actionsHeader)),
            ],
            rows: customers.map((customer) {
              return DataRow(
                cells: [
                  DataCell(Text(customer.name)),
                  DataCell(Text(customer.contactPerson ?? '-')),
                  DataCell(Text(customer.phone ?? '-')),
                  DataCell(Text(customer.email ?? '-')),
                  DataCell(Text(customer.city ?? '-')),
                  DataCell(
                    Text(
                      customer.isActive
                          ? l10n.activeStatus
                          : l10n.inactiveStatus,
                    ),
                  ),
                  if (canManageCustomers)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.editCustomerButton,
                            onPressed: () => onEdit(customer),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          if (customer.isActive)
                            IconButton(
                              tooltip: l10n.deactivateCustomerButton,
                              onPressed: () => onDeactivate(customer),
                              icon: const Icon(Icons.block_outlined),
                            )
                          else
                            IconButton(
                              tooltip: l10n.reactivateCustomerButton,
                              onPressed: () => onReactivate(customer),
                              icon: const Icon(Icons.check_circle_outline),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
