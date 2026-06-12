import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../dialogs/customer_details_dialog.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customers_state_view.dart';

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

  Future<void> _openCustomerDetails(Customer customer) async {
    final cubit = context.read<CustomersCubit>();
    cubit.loadCustomerActivity(customer);
    await showDialog<void>(
      context: context,
      builder: (_) => BlocBuilder<CustomersCubit, CustomersState>(
        builder: (context, state) {
          return CustomerDetailsDialog(
            customer: customer,
            state: state is CustomersLoaded ? state : null,
          );
        },
      ),
    );
    cubit.clearCustomerActivity();
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
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addCustomerButton),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomersStateView(
              state: state,
              onRetry: () => cubit.loadCustomers(widget.currentCompanyContext),
              onViewDetails: _openCustomerDetails,
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
