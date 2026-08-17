import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_lookup_option.dart';
import '../localization/trips_localizations_x.dart';

part 'trip_form_content.dart';
part 'trip_form_fields.dart';
part 'trip_form_parsers.dart';
part 'trip_form_submission.dart';

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

  void _setCustomerId(String? value) => setState(() => _customerId = value);

  void _setRouteId(String? value) => setState(() => _routeId = value);

  void _setDriverId(String? value) => setState(() => _driverId = value);

  void _setTractorHeadId(String? value) {
    setState(() => _tractorHeadId = value);
  }

  void _setTrailerId(String? value) => setState(() => _trailerId = value);

  void _setSubmitting(bool value) => setState(() => _isSubmitting = value);

  void _closeIfMounted() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
