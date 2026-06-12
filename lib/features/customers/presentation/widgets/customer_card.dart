import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/customer.dart';
import '../localization/customers_localizations_x.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool canManageCustomers;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const CustomerCard({
    required this.customer,
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
            if (customer.contactPerson != null) Text(l10n.contactPersonLine(customer.contactPerson!)),
            if (customer.phone != null) Text(l10n.phoneLine(customer.phone!)),
            if (customer.email != null) Text(l10n.emailLine(customer.email!)),
            if (customer.city != null) Text(l10n.cityLine(customer.city!)),
            Text(l10n.statusLine(customer.isActive ? l10n.activeStatus : l10n.inactiveStatus)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onViewDetails(customer),
                  icon: const Icon(AppIcons.view),
                  label: Text(l10n.customerViewDetails),
                ),
                if (canManageCustomers) ...[
                  OutlinedButton.icon(
                    onPressed: () => onEdit(customer),
                    icon: const Icon(AppIcons.edit),
                    label: Text(l10n.editCustomerButton),
                  ),
                  if (customer.isActive)
                    OutlinedButton.icon(
                      onPressed: () => onDeactivate(customer),
                      icon: const Icon(AppIcons.deactivate),
                      label: Text(l10n.deactivateCustomerButton),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => onReactivate(customer),
                      icon: const Icon(AppIcons.reactivate),
                      label: Text(l10n.reactivateCustomerButton),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
