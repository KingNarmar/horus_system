import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/customer.dart';
import 'customer_card.dart';

class CustomersCards extends StatelessWidget {
  final List<Customer> customers;
  final bool canManageCustomers;
  final ValueChanged<Customer> onViewDetails;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDeactivate;
  final ValueChanged<Customer> onReactivate;

  const CustomersCards({
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
    return Column(
      children: customers
          .map(
            (customer) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CustomerCard(
                customer: customer,
                canManageCustomers: canManageCustomers,
                onViewDetails: onViewDetails,
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
