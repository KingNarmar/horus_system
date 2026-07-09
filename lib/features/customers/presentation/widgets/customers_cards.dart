import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/active_state_confirmation_dialog.dart';
import '../../domain/entities/customer.dart';
import 'customer_card.dart';

class CustomersCards extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final String? pendingActionCustomerId;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const CustomersCards({
    required this.customers,
    required this.canManageCustomers,
    required this.pendingActionCustomerId,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns =
            constraints.maxWidth >= AppSizes.tabletMaxContentWidth;
        final cardWidth = useTwoColumns
            ? (constraints.maxWidth - AppSpacing.md) / 2
            : constraints.maxWidth;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: customers.map((customer) {
              return SizedBox(
                width: cardWidth,
                child: CustomerCard(
                  customer: customer,
                  canManageCustomers: canManageCustomers,
                  isActionInProgress: pendingActionCustomerId == customer.id,
                  onViewDetails: onViewDetails,
                  onEdit: onEdit,
                  onDeactivate: (customer) => _handle(context, customer),
                  onReactivate: (customer) => _handle(context, customer),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _handle(BuildContext context, Customer customer) async {
    final l10n = context.l10n;
    final active = customer.isActive;
    final confirmed = await showActiveStateConfirmationDialog(
      context: context,
      title: active
          ? l10n.customerConfirmDeactivateTitle
          : l10n.customerConfirmReactivateTitle,
      message: active
          ? l10n.customerConfirmDeactivateMessage
          : l10n.customerConfirmReactivateMessage,
      confirmLabel: active
          ? l10n.deactivateCustomerButton
          : l10n.reactivateCustomerButton,
      cancelLabel: l10n.cancelButton,
    );
    if (!confirmed) return;
    active ? onDeactivate(customer) : onReactivate(customer);
  }
}
