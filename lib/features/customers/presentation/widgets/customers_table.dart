import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/active_state_confirmation_dialog.dart';
import '../../domain/entities/customer.dart';
import '../localization/customers_localizations_x.dart';

class CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final String? pendingActionCustomerId;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const CustomersTable({required this.customers, required this.canManageCustomers, required this.pendingActionCustomerId, required this.onViewDetails, required this.onEdit, required this.onDeactivate, required this.onReactivate, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(builder: (context, constraints) {
      final tableMinWidth = constraints.maxWidth > AppSizes.desktopMinWidth ? constraints.maxWidth : AppSizes.desktopMinWidth;
      return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: ConstrainedBox(constraints: BoxConstraints(minWidth: tableMinWidth), child: DataTable(columns: [DataColumn(label: Text(l10n.customerNameHeader)), DataColumn(label: Text(l10n.contactHeader)), DataColumn(label: Text(l10n.phoneLabel)), DataColumn(label: Text(l10n.emailLabel)), DataColumn(label: Text(l10n.cityLabel)), DataColumn(label: Text(l10n.statusHeader)), DataColumn(label: Text(l10n.actionsHeader))], rows: customers.map((customer) {
        final loading = pendingActionCustomerId == customer.id;
        return DataRow(cells: [DataCell(Text(customer.name)), DataCell(Text(customer.contactPerson ?? l10n.customerEmptyValue)), DataCell(Text(customer.phone ?? l10n.customerEmptyValue)), DataCell(Text(customer.email ?? l10n.customerEmptyValue)), DataCell(Text(customer.city ?? l10n.customerEmptyValue)), DataCell(Text(customer.isActive ? l10n.activeStatus : l10n.inactiveStatus)), DataCell(Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: l10n.customerViewDetails, onPressed: () => onViewDetails(customer), icon: const Icon(AppIcons.view)), if (canManageCustomers) ...[IconButton(tooltip: l10n.editCustomerButton, onPressed: loading ? null : () => onEdit(customer), icon: const Icon(AppIcons.edit)), IconButton(tooltip: customer.isActive ? l10n.deactivateCustomerButton : l10n.reactivateCustomerButton, onPressed: loading ? null : () => _handle(context, customer), icon: _ActionIcon(isLoading: loading, icon: customer.isActive ? AppIcons.deactivate : AppIcons.reactivate))]]))]);
      }).toList()))));
    });
  }

  Future<void> _handle(BuildContext context, Customer customer) async {
    final l10n = context.l10n;
    final active = customer.isActive;
    final confirmed = await showActiveStateConfirmationDialog(context: context, title: active ? l10n.customerConfirmDeactivateTitle : l10n.customerConfirmReactivateTitle, message: active ? l10n.customerConfirmDeactivateMessage : l10n.customerConfirmReactivateMessage, confirmLabel: active ? l10n.deactivateCustomerButton : l10n.reactivateCustomerButton, cancelLabel: l10n.cancelButton);
    if (!confirmed) return;
    active ? onDeactivate(customer) : onReactivate(customer);
  }
}

class _ActionIcon extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  const _ActionIcon({required this.isLoading, required this.icon});
  @override
  Widget build(BuildContext context) => isLoading ? const SizedBox(width: AppSizes.iconMd, height: AppSizes.iconMd, child: CircularProgressIndicator(strokeWidth: AppSizes.loadingIndicatorStrokeWidth)) : Icon(icon);
}
