import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/customer.dart';
import '../localization/customers_localizations_x.dart';

class CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const CustomersTable({
    required this.customers,
    required this.canManageCustomers,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = constraints.maxWidth > AppSizes.desktopMinWidth
            ? constraints.maxWidth
            : AppSizes.desktopMinWidth;

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableMinWidth),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.customerNameHeader)),
                  DataColumn(label: Text(l10n.contactHeader)),
                  DataColumn(label: Text(l10n.phoneLabel)),
                  DataColumn(label: Text(l10n.emailLabel)),
                  DataColumn(label: Text(l10n.cityLabel)),
                  DataColumn(label: Text(l10n.statusHeader)),
                  DataColumn(label: Text(l10n.actionsHeader)),
                ],
                rows: customers.map((customer) {
                  return DataRow(cells: [
                    DataCell(Text(customer.name)),
                    DataCell(Text(customer.contactPerson ?? l10n.customerEmptyValue)),
                    DataCell(Text(customer.phone ?? l10n.customerEmptyValue)),
                    DataCell(Text(customer.email ?? l10n.customerEmptyValue)),
                    DataCell(Text(customer.city ?? l10n.customerEmptyValue)),
                    DataCell(Text(customer.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.customerViewDetails,
                          onPressed: () => onViewDetails(customer),
                          icon: const Icon(AppIcons.view),
                        ),
                        if (canManageCustomers) ...[
                          IconButton(
                            tooltip: l10n.editCustomerButton,
                            onPressed: () => onEdit(customer),
                            icon: const Icon(AppIcons.edit),
                          ),
                          if (customer.isActive)
                            IconButton(
                              tooltip: l10n.deactivateCustomerButton,
                              onPressed: () => onDeactivate(customer),
                              icon: const Icon(AppIcons.deactivate),
                            )
                          else
                            IconButton(
                              tooltip: l10n.reactivateCustomerButton,
                              onPressed: () => onReactivate(customer),
                              icon: const Icon(AppIcons.reactivate),
                            ),
                        ],
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
