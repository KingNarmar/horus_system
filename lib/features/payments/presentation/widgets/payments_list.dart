import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/money_formatter.dart';
import '../cubit/payments_state.dart';
import '../helpers/payment_formatters.dart';
import '../localization/payments_localizations.dart';

final class PaymentsList extends StatelessWidget {
  final PaymentsLoaded state;
  final int fractionDigits;

  const PaymentsList({
    required this.state,
    required this.fractionDigits,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final payments = state.visiblePayments;
    final strings = context.paymentsL10n;

    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            state.allPayments.isEmpty
                ? strings.noPayments
                : strings.noMatchingPayments,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
          return _PaymentsTable(state: state, fractionDigits: fractionDigits);
        }
        return _PaymentsCards(state: state, fractionDigits: fractionDigits);
      },
    );
  }
}

final class _PaymentsTable extends StatelessWidget {
  final PaymentsLoaded state;
  final int fractionDigits;

  const _PaymentsTable({required this.state, required this.fractionDigits});

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(strings.invoice)),
          DataColumn(label: Text(strings.customer)),
          DataColumn(label: Text(strings.paymentMethod)),
          DataColumn(label: Text(strings.paymentDate)),
          DataColumn(label: Text(strings.amount)),
          DataColumn(label: Text(strings.referenceNumber)),
        ],
        rows: state.visiblePayments
            .map((payment) {
              final invoice = state.invoiceFor(payment);
              final method = state.paymentMethodFor(payment);
              return DataRow(
                cells: [
                  DataCell(
                    Text(invoice?.number?.value ?? strings.unavailableValue),
                  ),
                  DataCell(
                    Text(invoice?.customer.name ?? strings.unavailableValue),
                  ),
                  DataCell(Text(method?.name ?? strings.unavailableValue)),
                  DataCell(
                    Text(formatPaymentDate(payment.paymentDate, localeName)),
                  ),
                  DataCell(
                    Text(
                      formatLocalizedMoney(
                        payment.amount,
                        fractionDigits: fractionDigits,
                        localeName: localeName,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(payment.referenceNumber ?? strings.unavailableValue),
                  ),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

final class _PaymentsCards extends StatelessWidget {
  final PaymentsLoaded state;
  final int fractionDigits;

  const _PaymentsCards({required this.state, required this.fractionDigits});

  @override
  Widget build(BuildContext context) {
    final strings = context.paymentsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      children: state.visiblePayments
          .map((payment) {
            final invoice = state.invoiceFor(payment);
            final method = state.paymentMethodFor(payment);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        invoice?.number?.value ?? strings.unavailableValue,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        label: strings.customer,
                        value:
                            invoice?.customer.name ?? strings.unavailableValue,
                      ),
                      _DetailRow(
                        label: strings.paymentMethod,
                        value: method?.name ?? strings.unavailableValue,
                      ),
                      _DetailRow(
                        label: strings.paymentDate,
                        value: formatPaymentDate(
                          payment.paymentDate,
                          localeName,
                        ),
                      ),
                      _DetailRow(
                        label: strings.amount,
                        value: formatLocalizedMoney(
                          payment.amount,
                          fractionDigits: fractionDigits,
                          localeName: localeName,
                        ),
                      ),
                      if (payment.referenceNumber != null)
                        _DetailRow(
                          label: strings.referenceNumber,
                          value: payment.referenceNumber!,
                        ),
                      if (payment.notes != null)
                        _DetailRow(label: strings.notes, value: payment.notes!),
                      _DetailRow(
                        label: strings.createdAt,
                        value: formatPaymentDateTime(
                          payment.createdAt,
                          localeName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

final class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}
