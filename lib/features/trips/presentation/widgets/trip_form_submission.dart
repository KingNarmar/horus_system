part of 'trip_form_dialog.dart';

extension _TripFormSubmission on _TripFormDialogState {
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final customerId = _customerId;
    final routeId = _routeId;

    if (customerId == null || routeId == null || _isSubmitting) return;

    _beginSubmitting();

    final result = await widget.onSubmit(
      TripFormData(
        customerId: customerId,
        routeId: routeId,
        driverId: _optionalSelected(_driverId),
        tractorHeadId: _optionalSelected(_tractorHeadId),
        trailerId: _optionalSelected(_trailerId),
        loadingOrderNumber: _optional(_loadingOrderController.text),
        waybillNumber: _optional(_waybillController.text),
        quantityTonsInput: _optional(_quantityController.text),
        agreedFreightRatePerTonInput: _optional(
          _agreedFreightRateController.text,
        ),
        scheduledLoadingAt: _scheduledLoadingAt,
        scheduledDeliveryAt: _scheduledDeliveryAt,
        actualLoadingAt: _actualLoadingAt,
        actualDeliveryAt: _actualDeliveryAt,
        notes: _optional(_notesController.text),
      ),
    );

    if (!mounted) return;

    if (result is TripMutationSucceeded) {
      _closeIfMounted();
      return;
    }

    if (result is TripMutationIgnored) {
      _closeIfMounted();
      return;
    }

    final failure = (result as TripMutationFailed).failure;
    _showSubmitFailure(failure);
  }
}
