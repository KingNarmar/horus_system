import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';
import '../cubit/invoices_state.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoices_localizations.dart';
import 'invoices_filters.dart';
import 'invoices_list.dart';

final class InvoicesStateView extends StatelessWidget {
  final InvoicesState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InvoiceStatus?> onStatusFilterChanged;
  final ValueChanged<Invoice> onViewDetails;

  const InvoicesStateView({
    required this.state,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onViewDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final currentState = state;

    if (currentState is InvoicesInitial || currentState is InvoicesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentState is InvoicesFailure) {
      return _MessageCard(
        message: context.localizedInvoiceFailure(currentState.failure),
        action: OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.retryButton),
        ),
      );
    }

    if (currentState is! InvoicesLoaded) return const SizedBox.shrink();

    final fractionDigits =
        currentState.currentCompanyContext.company.baseCurrencyFractionDigits ??
        0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InvoicesFilters(
          statusFilter: currentState.statusFilter,
          onSearchChanged: onSearchChanged,
          onStatusFilterChanged: onStatusFilterChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (currentState.allInvoices.isEmpty)
          _MessageCard(message: strings.noInvoices)
        else if (currentState.invoices.isEmpty)
          _MessageCard(message: strings.noMatchingInvoices)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return InvoicesList(
                invoices: currentState.invoices,
                currencyFractionDigits: fractionDigits,
                onViewDetails: onViewDetails,
                useTable: constraints.maxWidth >= AppSizes.dataTableBreakpoint,
              );
            },
          ),
      ],
    );
  }
}

final class _MessageCard extends StatelessWidget {
  final String message;
  final Widget? action;

  const _MessageCard({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
