import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_business_local_timestamps.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_lookup_option.dart';
import '../../domain/value_objects/quantity_tons.dart';
import '../helpers/trips_failure_message.dart';
import '../localization/trips_localizations_x.dart';
import '../models/trip_mutation_result.dart';
import 'trip_business_date_time_field.dart';

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
  final String? quantityTonsInput;
  final String? agreedFreightRatePerTonInput;
  final BusinessLocalDateTime? scheduledLoadingAt;
  final BusinessLocalDateTime? scheduledDeliveryAt;
  final BusinessLocalDateTime? actualLoadingAt;
  final BusinessLocalDateTime? actualDeliveryAt;
  final String? notes;

  const TripFormData({
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTonsInput,
    this.agreedFreightRatePerTonInput,
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
  final TripBusinessLocalTimestamps? initialBusinessLocalTimestamps;
  final TripFormLookups? lookups;
  final CurrencyConfiguration? financialConfiguration;
  final bool isLookupsLoading;
  final Failure? lookupsFailure;
  final Future<TripMutationResult> Function(TripFormData data) onSubmit;

  const TripFormDialog({
    required this.title,
    required this.onSubmit,
    required this.financialConfiguration,
    this.trip,
    this.initialBusinessLocalTimestamps,
    this.lookups,
    this.isLookupsLoading = false,
    this.lookupsFailure,
    super.key,
  });

  @override
  State<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<TripFormDialog> {
  static const _moneyCodec = MoneyDecimalCodec();
  static const _moneyInputParser = MoneyInputParser();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _loadingOrderController;
  late final TextEditingController _waybillController;
  late final TextEditingController _quantityController;
  late final TextEditingController _agreedFreightRateController;
  late final TextEditingController _notesController;

  String? _customerId;
  String? _routeId;
  String? _driverId;
  String? _tractorHeadId;
  String? _trailerId;
  BusinessLocalDateTime? _scheduledLoadingAt;
  BusinessLocalDateTime? _scheduledDeliveryAt;
  BusinessLocalDateTime? _actualLoadingAt;
  BusinessLocalDateTime? _actualDeliveryAt;
  bool _isSubmitting = false;
  Failure? _submitFailure;

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;
    final initialTimestamps = widget.initialBusinessLocalTimestamps;

    _customerId = trip?.customerId;
    _routeId = trip?.routeId;
    _driverId = trip?.driverId;
    _tractorHeadId = trip?.tractorHeadId;
    _trailerId = trip?.trailerId;
    _scheduledLoadingAt = initialTimestamps?.scheduledLoadingAt;
    _scheduledDeliveryAt = initialTimestamps?.scheduledDeliveryAt;
    _actualLoadingAt = initialTimestamps?.actualLoadingAt;
    _actualDeliveryAt = initialTimestamps?.actualDeliveryAt;

    _loadingOrderController = TextEditingController(
      text: trip?.loadingOrderNumber ?? '',
    );
    _waybillController = TextEditingController(text: trip?.waybillNumber ?? '');
    _quantityController = TextEditingController(
      text: _formatQuantityInput(trip?.quantityTons),
    );
    _agreedFreightRateController = TextEditingController(
      text: _formatMoneyInput(
        trip?.agreedFreightRatePerTon,
        widget.financialConfiguration,
      ),
    );
    _notesController = TextEditingController(text: trip?.notes ?? '');
  }

  @override
  void dispose() {
    _loadingOrderController.dispose();
    _waybillController.dispose();
    _quantityController.dispose();
    _agreedFreightRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: _content(context),
      ),
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
                    dimension: AppSizes.loadingIndicatorSm,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                    ),
                  )
                : const Icon(AppIcons.add),
            label: Text(l10n.tripSaveButton),
          ),
      ],
    );
  }

  void _setCustomerId(String? value) => setState(() => _customerId = value);

  void _setRouteId(String? value) {
    setState(() {
      _routeId = value;
      if (widget.trip != null) return;

      final route = widget.lookups?.routeById(value);
      _agreedFreightRateController.text = _formatMoneyInput(
        route?.defaultFreightRatePerTon,
        widget.financialConfiguration,
      );
    });
  }

  void _setDriverId(String? value) => setState(() => _driverId = value);

  void _setTractorHeadId(String? value) {
    setState(() => _tractorHeadId = value);
  }

  void _setTrailerId(String? value) => setState(() => _trailerId = value);

  void _closeIfMounted() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
