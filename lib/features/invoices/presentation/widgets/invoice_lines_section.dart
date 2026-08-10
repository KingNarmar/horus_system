import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/invoice.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceLinesSection extends StatelessWidget {
  final Invoice invoice;
  final int currencyFractionDigits;

  const InvoiceLinesSection({
    required this.invoice,
    required this.currencyFractionDigits,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...invoice.lines.map(
          (line) => _InvoiceLineCard(
            title: strings.lineReference(
              formatInvoiceLineReference(
                line,
                fallback: strings.unavailableValue,
              ),
            ),
            date: formatInvoiceDate(
              line.serviceDate,
              localeName,
              strings.unavailableValue,
            ),
            amount: formatInvoiceMoney(
              line.amount,
              fractionDigits: currencyFractionDigits,
              localeName: localeName,
            ),
          ),
        ),
      ],
    );
  }
}

final class _InvoiceLineCard extends StatelessWidget {
  final String title;
  final String date;
  final String amount;

  const _InvoiceLineCard({
    required this.title,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AppSizes.detailsStackBreakpoint) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(date),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    amount,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListTile(
            title: Text(title),
            subtitle: Text(date),
            trailing: Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }
}
