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
import 'invoice_draft_trip_selection.dart';

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
                InvoiceDraftTripSelection(
                  customerOptions: _customerOptions,
                  customerId: _customerId,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  dateRange: dateRange,
                  visibleTrips: _visibleTrips,
                  selectedTripIds: _selectedTripIds,
                  preview: _preview,
                  isCalculatingPreview: _isCalculatingPreview,
                  isSaving: _isSubmitting,
                  showTripRequired: _showTripRequired,
                  currencyFractionDigits: widget.currencyFractionDigits,
                  onCustomerChanged: _onCustomerChanged,
                  onPickFromDate: dateRange == null
                      ? () {}
                      : () => _pickDate(isFrom: true, range: dateRange),
                  onPickToDate: dateRange == null
                      ? () {}
                      : () => _pickDate(isFrom: false, range: dateRange),
                  onClearDateFilters: _clearDateFilters,
                  onSearchChanged: (value) {
                    setState(() => _tripSearch = value);
                  },
                  onTripChanged: (trip, selected) {
                    _toggleTrip(trip, selected: selected);
                  },
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

  List<InvoiceDraftCustomerOption> get _customerOptions {
    final options = <String, String?>{};
    for (final trip in widget.billableTrips) {
      options.putIfAbsent(trip.customerId, () => _nonBlank(trip.customerName));
    }
    final result = options.entries
        .map(
          (entry) => InvoiceDraftCustomerOption(
            id: entry.key,
            name: entry.value,
          ),
        )
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

  InvoiceDraftDateRange? get _dateRange {
    final dates = _customerTrips
        .map((trip) => trip.serviceDate)
        .whereType<BusinessDate>()
        .toList(growable: false);
    if (dates.isEmpty) return null;
    dates.sort();
    return InvoiceDraftDateRange(first: dates.first, last: dates.last);
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

  void _clearDateFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _pickDate({
    required bool isFrom,
    required InvoiceDraftDateRange range,
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
