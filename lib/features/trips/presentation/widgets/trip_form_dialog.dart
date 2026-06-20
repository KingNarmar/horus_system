import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_lookup_option.dart';
import '../localization/trips_localizations_x.dart';

class TripFormData {
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final double? quantityTons;
  final double? freightPrice;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;

  const TripFormData({
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.freightPrice,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
  });
}

class TripFormDialog extends StatefulWidget {
  final String title;
  final TripEntity? trip;
  final TripFormLookups? lookups;
  final bool isLookupsLoading;
  final Failure? lookupsFailure;
  final Future<void> Function(TripFormData data) onSubmit;

  const TripFormDialog({
    required this.title,
    required this.onSubmit,
    this.trip,
    this.lookups,
    this.isLookupsLoading = false,
    this.lookupsFailure,
    super.key,
  });

  @override
  State<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<TripFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _loadingOrderController;
  late final TextEditingController _waybillController;
  late final TextEditingController _quantityController;
  late final TextEditingController _freightPriceController;
  late final TextEditingController _scheduledLoadingController;
  late final TextEditingController _scheduledDeliveryController;
  late final TextEditingController _actualLoadingController;
  late final TextEditingController _actualDeliveryController;
  late final TextEditingController _notesController;

  String? _customerId;
  String? _routeId;
  String? _driverId;
  String? _tractorHeadId;
  String? _trailerId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;

    _customerId = trip?.customerId;
    _routeId = trip?.routeId;
    _driverId = trip?.driverId;
    _tractorHeadId = trip?.tractorHeadId;
    _trailerId = trip?.trailerId;

    _loadingOrderController = TextEditingController(
      text: trip?.loadingOrderNumber ?? '',
    );
    _waybillController = TextEditingController(text: trip?.waybillNumber ?? '');
    _quantityController = TextEditingController(
      text: _formatDouble(trip?.quantityTons),
    );
    _freightPriceController = TextEditingController(
      text: _formatDouble(trip?.freightPrice),
    );
    _scheduledLoadingController = TextEditingController(
      text: _formatDateTimeForInput(trip?.scheduledLoadingAt),
    );
    _scheduledDeliveryController = TextEditingController(
      text: _formatDateTimeForInput(trip?.scheduledDeliveryAt),
    );
    _actualLoadingController = TextEditingController(
      text: _formatDateTimeForInput(trip?.actualLoadingAt),
    );
    _actualDeliveryController = TextEditingController(
      text: _formatDateTimeForInput(trip?.actualDeliveryAt),
    );
    _notesController = TextEditingController(text: trip?.notes ?? '');
  }

  @override
  void dispose() {
    _loadingOrderController.dispose();
    _waybillController.dispose();
    _quantityController.dispose();
    _freightPriceController.dispose();
    _scheduledLoadingController.dispose();
    _scheduledDeliveryController.dispose();
    _actualLoadingController.dispose();
    _actualDeliveryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(width: 680, child: _content(context)),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.tripCancelButton),
        ),
        if (_canSubmit)
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.add),
            label: Text(l10n.tripSaveButton),
          ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.l10n;

    if (widget.isLookupsLoading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppSpacing.md),
            Text(l10n.tripLoadingLookups),
          ],
        ),
      );
    }

    final failure = widget.lookupsFailure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(l10n.localizedErrorMessage(failure)),
      );
    }

    final lookups = widget.lookups;
    if (lookups == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(l10n.tripLoadingLookups),
      );
    }

    if (!lookups.hasRequiredLookups) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(l10n.tripRequiredLookupsMissing),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _requiredDropdown(
              label: l10n.tripCustomerHeader,
              value: _validSelectedValue(_customerId, lookups.customers),
              options: lookups.customers,
              validatorMessage: l10n.tripCustomerRequired,
              onChanged: (value) => setState(() => _customerId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _requiredDropdown(
              label: l10n.tripRouteHeader,
              value: _validSelectedValue(_routeId, lookups.routes),
              options: lookups.routes,
              validatorMessage: l10n.tripRouteRequired,
              onChanged: (value) => setState(() => _routeId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _optionalDropdown(
              label: l10n.tripDriverHeader,
              value: _validSelectedValue(_driverId, lookups.drivers),
              options: lookups.drivers,
              onChanged: (value) => setState(() => _driverId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _optionalDropdown(
              label: l10n.tripTractorHeadLabel,
              value: _validSelectedValue(_tractorHeadId, lookups.tractorHeads),
              options: lookups.tractorHeads,
              onChanged: (value) => setState(() => _tractorHeadId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _optionalDropdown(
              label: l10n.tripTrailerLabel,
              value: _validSelectedValue(_trailerId, lookups.trailers),
              options: lookups.trailers,
              onChanged: (value) => setState(() => _trailerId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _loadingOrderController,
              decoration: InputDecoration(
                labelText: l10n.tripLoadingOrderHeader,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _waybillController,
              decoration: InputDecoration(labelText: l10n.tripWaybillHeader),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.tripQuantityHeader),
              validator: (_) {
                return _nonNegativeNumberValid(_quantityController.text)
                    ? null
                    : l10n.tripNumberInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _freightPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.tripFreightPriceHeader,
              ),
              validator: (_) {
                return _nonNegativeNumberValid(_freightPriceController.text)
                    ? null
                    : l10n.tripNumberInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _scheduledLoadingController,
              decoration: InputDecoration(
                labelText: l10n.tripScheduledLoadingAtLabel,
                helperText: l10n.tripDateTimeHelperText,
              ),
              validator: (_) {
                return _dateTimeValid(_scheduledLoadingController.text)
                    ? null
                    : l10n.tripDateTimeInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _scheduledDeliveryController,
              decoration: InputDecoration(
                labelText: l10n.tripScheduledDeliveryAtLabel,
                helperText: l10n.tripDateTimeHelperText,
              ),
              validator: (_) {
                if (!_dateTimeValid(_scheduledDeliveryController.text)) {
                  return l10n.tripDateTimeInvalid;
                }

                final loading = _parseDateTime(
                  _scheduledLoadingController.text,
                );
                final delivery = _parseDateTime(
                  _scheduledDeliveryController.text,
                );

                if (loading != null &&
                    delivery != null &&
                    delivery.isBefore(loading)) {
                  return l10n.tripDeliveryBeforeLoadingInvalid;
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _actualLoadingController,
              decoration: InputDecoration(
                labelText: l10n.tripActualLoadingAtLabel,
                helperText: l10n.tripDateTimeHelperText,
              ),
              validator: (_) {
                return _dateTimeValid(_actualLoadingController.text)
                    ? null
                    : l10n.tripDateTimeInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _actualDeliveryController,
              decoration: InputDecoration(
                labelText: l10n.tripActualDeliveryAtLabel,
                helperText: l10n.tripDateTimeHelperText,
              ),
              validator: (_) {
                return _dateTimeValid(_actualDeliveryController.text)
                    ? null
                    : l10n.tripDateTimeInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.tripNotesLabel),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    return !widget.isLookupsLoading &&
        widget.lookupsFailure == null &&
        widget.lookups != null &&
        widget.lookups!.hasRequiredLookups;
  }

  Widget _requiredDropdown({
    required String label,
    required String? value,
    required List<TripLookupOption> options,
    required String validatorMessage,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.id,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: _isSubmitting ? null : onChanged,
      validator: (value) {
        return value == null || value.trim().isEmpty ? validatorMessage : null;
      },
    );
  }

  Widget _optionalDropdown({
    required String label,
    required String? value,
    required List<TripLookupOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    final l10n = context.l10n;

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(value: '', child: Text(l10n.tripOptionalNone)),
        ...options.map((option) {
          return DropdownMenuItem<String>(
            value: option.id,
            child: Text(option.label),
          );
        }),
      ],
      onChanged: _isSubmitting
          ? null
          : (value) => onChanged(value == null || value.isEmpty ? null : value),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final customerId = _customerId;
    final routeId = _routeId;

    if (customerId == null || routeId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    await widget.onSubmit(
      TripFormData(
        customerId: customerId,
        routeId: routeId,
        driverId: _optionalSelected(_driverId),
        tractorHeadId: _optionalSelected(_tractorHeadId),
        trailerId: _optionalSelected(_trailerId),
        loadingOrderNumber: _optional(_loadingOrderController.text),
        waybillNumber: _optional(_waybillController.text),
        quantityTons: _parseDouble(_quantityController.text),
        freightPrice: _parseDouble(_freightPriceController.text),
        scheduledLoadingAt: _parseDateTime(_scheduledLoadingController.text),
        scheduledDeliveryAt: _parseDateTime(_scheduledDeliveryController.text),
        actualLoadingAt: _parseDateTime(_actualLoadingController.text),
        actualDeliveryAt: _parseDateTime(_actualDeliveryController.text),
        notes: _optional(_notesController.text),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

String? _validSelectedValue(String? value, List<TripLookupOption> options) {
  if (value == null || value.trim().isEmpty) return null;

  final exists = options.any((option) => option.id == value);
  return exists ? value : null;
}

String? _optionalSelected(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _optional(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

bool _nonNegativeNumberValid(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;

  final number = _parseDouble(text);
  return number != null && number >= 0;
}

double? _parseDouble(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  return double.tryParse(text.replaceAll(',', '.'));
}

bool _dateTimeValid(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;

  return _parseDateTime(text) != null;
}

DateTime? _parseDateTime(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

String _formatDouble(double? value) {
  if (value == null) return '';

  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String _formatDateTimeForInput(DateTime? value) {
  if (value == null) return '';

  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}
