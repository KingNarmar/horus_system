part of 'trip_form_dialog.dart';

extension _TripFormContent on _TripFormDialogState {
  Widget _content(BuildContext context) {
    final l10n = context.l10n;

    if (widget.isLookupsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (widget.lookupsFailure != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(l10n.localizedErrorMessage(widget.lookupsFailure!)),
      );
    }

    final lookups = widget.lookups;
    if (lookups == null || !lookups.hasRequiredLookups) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(l10n.tripRequiredLookupsMissing),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_submitFailure != null) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  tripsFailureMessage(context, _submitFailure!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _requiredDropdown(
              label: l10n.tripCustomerHeader,
              value: _validSelectedValue(_customerId, lookups.customers),
              options: lookups.customers,
              validatorMessage: l10n.tripCustomerRequired,
              onChanged: _setCustomerId,
            ),
            const SizedBox(height: AppSpacing.md),
            _requiredDropdown(
              label: l10n.tripRouteHeader,
              value: _validSelectedValue(_routeId, lookups.routes),
              options: lookups.routes,
              validatorMessage: l10n.tripRouteRequired,
              onChanged: _setRouteId,
            ),
            const SizedBox(height: AppSpacing.md),
            _optionalDropdown(
              label: l10n.tripDriverHeader,
              value: _validSelectedValue(_driverId, lookups.drivers),
              options: lookups.drivers,
              onChanged: _setDriverId,
            ),
            const SizedBox(height: AppSpacing.md),
            _optionalDropdown(
              label: l10n.tripTractorHeadLabel,
              value: _validSelectedValue(_tractorHeadId, lookups.tractorHeads),
              options: lookups.tractorHeads,
              onChanged: _setTractorHeadId,
            ),
            const SizedBox(height: AppSpacing.md),
            _optionalDropdown(
              label: l10n.tripTrailerLabel,
              value: _validSelectedValue(_trailerId, lookups.trailers),
              options: lookups.trailers,
              onChanged: _setTrailerId,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _loadingOrderController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.tripLoadingOrderHeader,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _waybillController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.tripWaybillHeader,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _quantityController,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.tripQuantityHeader,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                return _quantityValid(value ?? '')
                    ? null
                    : l10n.tripNumberInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _agreedFreightRateController,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.tripAgreedFreightRatePerTonLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                return _moneyInputValid(
                      value ?? '',
                      widget.financialConfiguration,
                    )
                    ? null
                    : l10n.tripNumberInvalid;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TripBusinessDateTimeField(
              label: l10n.tripScheduledLoadingAtLabel,
              value: _scheduledLoadingAt,
              enabled: !_isSubmitting,
              onChanged: (value) => setState(() {
                _scheduledLoadingAt = value;
                _submitFailure = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            TripBusinessDateTimeField(
              label: l10n.tripScheduledDeliveryAtLabel,
              value: _scheduledDeliveryAt,
              enabled: !_isSubmitting,
              onChanged: (value) => setState(() {
                _scheduledDeliveryAt = value;
                _submitFailure = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            TripBusinessDateTimeField(
              label: l10n.tripActualLoadingAtLabel,
              value: _actualLoadingAt,
              enabled: !_isSubmitting,
              onChanged: (value) => setState(() {
                _actualLoadingAt = value;
                _submitFailure = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            TripBusinessDateTimeField(
              label: l10n.tripActualDeliveryAtLabel,
              value: _actualDeliveryAt,
              enabled: !_isSubmitting,
              onChanged: (value) => setState(() {
                _actualDeliveryAt = value;
                _submitFailure = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              enabled: !_isSubmitting,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.tripNotesLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    final lookups = widget.lookups;
    return !widget.isLookupsLoading &&
        widget.lookupsFailure == null &&
        lookups != null &&
        lookups.hasRequiredLookups;
  }
}
