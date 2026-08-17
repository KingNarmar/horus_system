part of 'trip_form_dialog.dart';

extension _TripFormSubmission on _TripFormDialogState {
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final customerId = _customerId;
    final routeId = _routeId;

    if (customerId == null || routeId == null || _isSubmitting) return;

    _setSubmitting(true);

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

    _closeIfMounted();
  }
}
