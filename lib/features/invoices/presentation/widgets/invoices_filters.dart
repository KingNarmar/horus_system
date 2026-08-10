import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/invoice_status.dart';
import '../localization/invoice_status_localizations_x.dart';
import '../localization/invoices_localizations.dart';

final class InvoicesFilters extends StatelessWidget {
  final InvoiceStatus? statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InvoiceStatus?> onStatusFilterChanged;

  const InvoicesFilters({
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.searchFieldMaxWidth,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.search),
              hintText: strings.searchHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        DropdownButton<InvoiceStatus?>(
          value: statusFilter,
          items: [
            DropdownMenuItem<InvoiceStatus?>(
              value: null,
              child: Text(strings.allStatuses),
            ),
            ...InvoiceStatus.values.map((status) {
              return DropdownMenuItem<InvoiceStatus?>(
                value: status,
                child: Text(status.localizedLabel(strings)),
              );
            }),
          ],
          onChanged: onStatusFilterChanged,
        ),
      ],
    );
  }
}
