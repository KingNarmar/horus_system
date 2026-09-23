import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice_totals.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceDraftCustomerOption {
  final String id;
  final String? name;

  const InvoiceDraftCustomerOption({required this.id, required this.name});
}

final class InvoiceDraftDateRange {
  final BusinessDate first;
  final BusinessDate last;

  const InvoiceDraftDateRange({required this.first, required this.last});
}

final class InvoiceDraftTripSelection extends StatelessWidget {
  final List<InvoiceDraftCustomerOption> customerOptions;
  final String? customerId;
  final BusinessDate? fromDate;
  final BusinessDate? toDate;
  final InvoiceDraftDateRange? dateRange;
  final List<BillableTrip> visibleTrips;
  final Set<String> selectedTripIds;
  final InvoiceTotals? preview;
  final bool isCalculatingPreview;
  final bool isSaving;
  final bool showTripRequired;
  final int currencyFractionDigits;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onClearDateFilters;
  final ValueChanged<String> onSearchChanged;
  final void Function(BillableTrip trip, bool selected) onTripChanged;

  const InvoiceDraftTripSelection({
    required this.customerOptions,
    required this.customerId,
    required this.fromDate,
    required this.toDate,
    required this.dateRange,
    required this.visibleTrips,
    required this.selectedTripIds,
    required this.preview,
    required this.isCalculatingPreview,
    required this.isSaving,
    required this.showTripRequired,
    required this.currencyFractionDigits,
    required this.onCustomerChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onClearDateFilters,
    required this.onSearchChanged,
    required this.onTripChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final selectedCount = selectedTripIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const ValueKey('invoiceDraftCustomerField'),
          initialValue: customerId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: strings.customer,
            border: const OutlineInputBorder(),
          ),
          hint: Text(strings.selectCustomer),
          items: customerOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.id,
                  child: Text(
                    option.name ?? strings.unavailableValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: isSaving ? null : onCustomerChanged,
          validator: (value) {
            return value == null || value.trim().isEmpty
                ? strings.customerRequiredFailure
                : null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _DateFilters(
          fromDate: fromDate,
          toDate: toDate,
          dateRange: dateRange,
          isSaving: isSaving,
          localeName: localeName,
          strings: strings,
          onPickFromDate: onPickFromDate,
          onPickToDate: onPickToDate,
          onClearDateFilters: onClearDateFilters,
        ),
        TextFormField(
          key: const ValueKey('invoiceDraftTripSearchField'),
          enabled: !isSaving && customerId != null,
          decoration: InputDecoration(
            labelText: strings.searchBillableTrips,
            prefixIcon: const Icon(AppIcons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.billableTrips,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (customerId == null)
          _MessageCard(message: strings.selectCustomer)
        else if (visibleTrips.isEmpty)
          _MessageCard(message: strings.noTripsForCustomer)
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: visibleTrips
                  .map(
                    (trip) => CheckboxListTile(
                      key: ValueKey('invoiceDraftTrip-${trip.id}'),
                      value: selectedTripIds.contains(trip.id),
                      enabled: !isSaving,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        formatBillableTripReference(
                          trip,
                          localeName: localeName,
                          fallback: strings.unavailableValue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        formatInvoiceMoney(
                          trip.freightAmount,
                          fractionDigits: currencyFractionDigits,
                          localeName: localeName,
                        ),
                      ),
                      onChanged: (selected) =>
                          onTripChanged(trip, selected ?? false),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (showTripRequired && selectedCount == 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.tripRequired,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (selectedCount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          _PreviewCard(
            preview: preview,
            isCalculating: isCalculatingPreview,
            selectedCount: selectedCount,
            currencyFractionDigits: currencyFractionDigits,
            localeName: localeName,
            strings: strings,
          ),
        ],
      ],
    );
  }
}

final class _DateFilters extends StatelessWidget {
  final BusinessDate? fromDate;
  final BusinessDate? toDate;
  final InvoiceDraftDateRange? dateRange;
  final bool isSaving;
  final String localeName;
  final InvoicesLocalizations strings;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onClearDateFilters;

  const _DateFilters({
    required this.fromDate,
    required this.toDate,
    required this.dateRange,
    required this.isSaving,
    required this.localeName,
    required this.strings,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onClearDateFilters,
  });

  @override
  Widget build(BuildContext context) {
    final fromButton = OutlinedButton.icon(
      key: const ValueKey('invoiceDraftFromDateButton'),
      onPressed: isSaving || dateRange == null ? null : onPickFromDate,
      icon: const Icon(AppIcons.calendar),
      label: Text(
        fromDate == null
            ? strings.fromDate
            : '${strings.fromDate}: '
                  '${formatInvoiceDate(fromDate, localeName, strings.unavailableValue)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    final toButton = OutlinedButton.icon(
      key: const ValueKey('invoiceDraftToDateButton'),
      onPressed: isSaving || dateRange == null ? null : onPickToDate,
      icon: const Icon(AppIcons.calendar),
      label: Text(
        toDate == null
            ? strings.toDate
            : '${strings.toDate}: '
                  '${formatInvoiceDate(toDate, localeName, strings.unavailableValue)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < AppSizes.detailsStackBreakpoint) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fromButton,
                  const SizedBox(height: AppSpacing.sm),
                  toButton,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: fromButton),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: toButton),
              ],
            );
          },
        ),
        if (fromDate != null || toDate != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: isSaving ? null : onClearDateFilters,
              icon: const Icon(AppIcons.clear),
              label: Text(strings.clearDateFilters),
            ),
          )
        else
          const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

final class _PreviewCard extends StatelessWidget {
  final InvoiceTotals? preview;
  final bool isCalculating;
  final int selectedCount;
  final int currencyFractionDigits;
  final String localeName;
  final InvoicesLocalizations strings;

  const _PreviewCard({
    required this.preview,
    required this.isCalculating,
    required this.selectedCount,
    required this.currencyFractionDigits,
    required this.localeName,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.draftPreview,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(strings.selectedTripsCount(selectedCount)),
            if (isCalculating) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(),
            ] else if (preview != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _PreviewRow(
                label: strings.subtotal,
                value: formatInvoiceMoney(
                  preview!.subtotal,
                  fractionDigits: currencyFractionDigits,
                  localeName: localeName,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _PreviewRow(
                label: strings.total,
                value: formatInvoiceMoney(
                  preview!.grandTotal,
                  fractionDigits: currencyFractionDigits,
                  localeName: localeName,
                ),
                emphasize: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: AppSpacing.md),
        Text(value, style: style),
      ],
    );
  }
}

final class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
