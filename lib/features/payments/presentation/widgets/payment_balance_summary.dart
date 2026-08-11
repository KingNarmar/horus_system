import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/money_formatter.dart';
import '../../domain/entities/payable_invoice.dart';
import '../localization/payments_localizations.dart';

final class PaymentBalanceSummary extends StatelessWidget {
  final PayableInvoice payableInvoice;
  final int fractionDigits;
  final String localeName;

  const PaymentBalanceSummary({
    required this.payableInvoice,
    required this.fractionDigits,
    required this.localeName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;
    final balance = payableInvoice.balance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BalanceRow(
              label: strings.total,
              value: formatLocalizedMoney(
                balance.total,
                fractionDigits: fractionDigits,
                localeName: localeName,
              ),
            ),
            _BalanceRow(
              label: strings.paid,
              value: formatLocalizedMoney(
                balance.paid,
                fractionDigits: fractionDigits,
                localeName: localeName,
              ),
            ),
            _BalanceRow(
              label: strings.remaining,
              value: formatLocalizedMoney(
                balance.remaining,
                fractionDigits: fractionDigits,
                localeName: localeName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
