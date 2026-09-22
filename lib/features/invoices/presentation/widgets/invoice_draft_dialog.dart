import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../../core/utils/search_text_normalizer.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice_totals.dart';
import '../cubit/invoice_draft_form_input.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoices_localizations.dart';

typedef InvoiceDraftPreviewCallback =
    Future<InvoiceTotals?> Function({
      required String customerId,
      required List<BillableTrip> trips,
    });

final class InvoiceDraftDialog extends StatefulWidget {
  final List<BillableTrip> billableTrips;
  final int currencyFractionDigits;
  final InvoiceDraftPreviewCallback onCalculatePreview;
  final Future<bool> Function(InvoiceDraftFormInput input) onSubmit;

  const InvoiceDraftDialog({
    required this.billableTrips,
    required this.currencyFractionDigits,
    required this.onCalculatePreview,
    required this.onSubmit,
    super.key,
  });

  @override
  State<InvoiceDraftDialog> createState() => _InvoiceDraftDialogState();
}

final class _InvoiceDraftDialogState extends State<InvoiceDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _customerId;
  String _tripSearch = '';
  BusinessDate? _fromDate;
  BusinessDate? _toDate;
  final Set<String> _selectedTripIds = <String>{};

  InvoiceTotals? _preview;
  bool _isCalculatingPreview = false;
  bool _isSubmitting = false;
  bool _showTripRequired = false;
  int _previewGeneration = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final visibleTrips = _visibleTrips;
    final selectedTrips = _selectedTrips;
    final dateRange = _dateRange;

    return AlertDialog(
      title: Text(strings.createDraftTitle),
      content: SizedBox(
        width: AppSizes.detailsDialogMaxWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: const ValueKey('invoiceDraftCustomerField'),
                  initialValue: _customerId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: strings.customer,
                    border: const OutlineInputBorder(),
                  ),
                  hint: Text(strings.selectCustomer),
                  items: _customerOptions
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
                  onChanged: _isSubmitting ? null : _onCustomerChanged,
                  validator: (value) {
                    return value == null || value.trim().isEmpty
                        ? strings.customerRequiredFailure
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fromButton = OutlinedButton.icon(
                      key: const ValueKey('invoiceDraftFromDateButton'),
                      onPressed:
                          _isSubmitting || dateRange == null
                          ? null
                          : () => _pickDate(isFrom: true, range: dateRange),
                      icon: const Icon(AppIcons.calendar),
                      label: Text(
                        _fromDate == null
                            ? strings.fromDate
                            : '${strings.fromDate}: '
                                  '${formatInvoiceDate(_fromDate, localeName, strings.unavailableValue)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                    final toButton = OutlinedButton.icon(
                      key: const ValueKey('invoiceDraftToDateButton'),
                      onPressed:
                          _isSubmitting || dateRange == null
                          ? null
                          : () => _pickDate(isFrom: false, range: dateRange),
                      icon: const Icon(AppIcons.calendar),
                      label: Text(
                        _toDate == null
                            ? strings.toDate
                            : '${strings.toDate}: '
                                  '${formatInvoiceDate(_toDate, localeName, strings.unavailableValue)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );

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
                if (_fromDate != null || _toDate != null) ...[
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _fromDate = null;
                                _toDate = null;
                              });
                            },
                      icon: const Icon(AppIcons.clear),
                      label: Text(strings.clearDateFilters),
                    ),
                  ),
                ] else
                  const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const ValueKey('invoiceDraftTripSearchField'),
                  enabled: !_isSubmitting && _customerId != null,
                  decoration: InputDecoration(
                    labelText: strings.searchBillableTrips,
                    prefixIcon: const Icon(AppIcons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _tripSearch = value),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.billableTrips,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_customerId == null)
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
                              value: _selectedTripIds.contains(trip.id),
                              enabled: !_isSubmitting,
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
                                  fractionDigits: widget.currencyFractionDigits,
                                  localeName: localeName,
                                ),
                              ),
                              onChanged: (selected) => _toggleTrip(
                                trip,
                                selected: selected ?? false,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                if (_showTripRequired && selectedTrips.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    strings.tripRequired,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _buildPreview(
                  context,
                  strings: strings,
                  localeName: localeName,
                  selectedTrips: selectedTrips,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: strings.notes,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton.icon(
          key: const ValueKey('invoiceDraftSaveButton'),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: AppSizes.loadingIndicatorSm,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                  ),
                )
              : const Icon(AppIcons.add),
          label: Text(_isSubmitting ? strings.savingDraft : strings.saveDraft),
        ),
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context, {
    required InvoicesLocalizations strings,
    required String localeName,
    required List<BillableTrip> selectedTrips,
  }) {
    if (selectedTrips.isEmpty) return const SizedBox.shrink();

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
            Text(strings.selectedTripsCount(selectedTrips.length)),
            if (_isCalculatingPreview) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(),
            ] else if (_preview != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _PreviewRow(
                label: strings.subtotal,
                value: formatInvoiceMoney(
                  _preview!.subtotal,
                  fractionDigits: widget.currencyFractionDigits,
                  localeName: localeName,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _PreviewRow(
                label: strings.total,
                value: formatInvoiceMoney(
                  _preview!.grandTotal,
                  fractionDigits: widget.currencyFractionDigits,
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

  List<_CustomerOption> get _customerOptions {
    final options = <String, String?>{};
    for (final trip in widget.billableTrips) {
      options.putIfAbsent(trip.customerId, () => _nonBlank(trip.customerName));
    }
    final result = options.entries
        .map((entry) => _CustomerOption(id: entry.key, name: entry.value))
        .toList(growable: false);
    result.sort(
      (left, right) => (left.name ?? '').toLowerCase().compareTo(
        (right.name ?? '').toLowerCase(),
      ),
    );
    return result;
  }

  List<BillableTrip> get _customerTrips {
    final customerId = _customerId;
    if (customerId == null) return const [];
    return widget.billableTrips
        .where((trip) => trip.customerId == customerId)
        .toList(growable: false);
  }

  List<BillableTrip> get _visibleTrips {
    final normalizedSearch = normalizeSearchText(_tripSearch);
    return _customerTrips.where((trip) {
      final serviceDate = trip.serviceDate;
      if (_fromDate != null &&
          (serviceDate == null || serviceDate.isBefore(_fromDate!))) {
        return false;
      }
      if (_toDate != null &&
          (serviceDate == null || serviceDate.isAfter(_toDate!))) {
        return false;
      }
      if (normalizedSearch.isEmpty) return true;

      final terms = <Object?>[
        trip.tripNumber,
        trip.loadingOrderNumber,
        trip.waybillNumber,
        trip.loadingLocation,
        trip.unloadingLocation,
        trip.customerName,
        formatInvoiceInputDate(trip.serviceDate),
      ];
      return terms.any((term) {
        if (term == null) return false;
        return normalizeSearchText(term.toString()).contains(normalizedSearch);
      });
    }).toList(growable: false);
  }

  List<BillableTrip> get _selectedTrips {
    return widget.billableTrips
        .where((trip) => _selectedTripIds.contains(trip.id))
        .toList(growable: false);
  }

  _DateRange? get _dateRange {
    final dates = _customerTrips
        .map((trip) => trip.serviceDate)
        .whereType<BusinessDate>()
        .toList(growable: false);
    if (dates.isEmpty) return null;
    dates.sort();
    return _DateRange(first: dates.first, last: dates.last);
  }

  void _onCustomerChanged(String? customerId) {
    _previewGeneration++;
    setState(() {
      _customerId = customerId;
      _fromDate = null;
      _toDate = null;
      _selectedTripIds.clear();
      _preview = null;
      _isCalculatingPreview = false;
      _showTripRequired = false;
    });
  }

  Future<void> _pickDate({
    required bool isFrom,
    required _DateRange range,
  }) async {
    final current = isFrom ? _fromDate : _toDate;
    final initial = current ?? (isFrom ? range.first : range.last);
    final picked = await showDatePicker(
      context: context,
      initialDate: BusinessDateDateTimeAdapter.toDateTime(initial),
      firstDate: BusinessDateDateTimeAdapter.toDateTime(range.first),
      lastDate: BusinessDateDateTimeAdapter.toDateTime(range.last),
    );
    if (picked == null || !mounted) return;

    final businessDate = BusinessDate(
      year: picked.year,
      month: picked.month,
      day: picked.day,
    );
    setState(() {
      if (isFrom) {
        _fromDate = businessDate;
      } else {
        _toDate = businessDate;
      }
    });
  }

  Future<void> _toggleTrip(
    BillableTrip trip, {
    required bool selected,
  }) async {
    if (trip.customerId != _customerId) return;

    setState(() {
      if (selected) {
        _selectedTripIds.add(trip.id);
      } else {
        _selectedTripIds.remove(trip.id);
      }
      _showTripRequired = false;
    });
    await _recalculatePreview();
  }

  Future<void> _recalculatePreview() async {
    final customerId = _customerId;
    final trips = _selectedTrips;
    final generation = ++_previewGeneration;

    if (customerId == null || trips.isEmpty) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _isCalculatingPreview = false;
      });
      return;
    }

    setState(() => _isCalculatingPreview = true);
    final preview = await widget.onCalculatePreview(
      customerId: customerId,
      trips: trips,
    );
    if (!mounted || generation != _previewGeneration) return;

    setState(() {
      _preview = preview;
      _isCalculatingPreview = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final customerId = _customerId;
    final trips = _selectedTrips;
    if (customerId == null || trips.isEmpty) {
      setState(() => _showTripRequired = true);
      return;
    }

    if (_preview == null) {
      await _recalculatePreview();
      if (!mounted || _preview == null) return;
    }

    setState(() => _isSubmitting = true);
    final saved = await widget.onSubmit(
      InvoiceDraftFormInput.fromBillableTrips(
        trips,
        customerId: customerId,
        notes: _optional(_notesController.text),
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSubmitting = false);
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _nonBlank(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

final class _CustomerOption {
  final String id;
  final String? name;

  const _CustomerOption({required this.id, required this.name});
}

final class _DateRange {
  final BusinessDate first;
  final BusinessDate last;

  const _DateRange({required this.first, required this.last});
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
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )
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
