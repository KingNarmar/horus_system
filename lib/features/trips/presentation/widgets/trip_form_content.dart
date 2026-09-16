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
              decoration: InputDecoration(
                labelText: l10n.tripLoadingOrderHeader,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _waybillController,
              decoration: InputDecoration(
                labelText: l10n.tripWaybillHeader,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _quantityController,
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
            TextFormField(
              controller: _scheduledLoadingController,
              decoration: InputDecoration(
                labelText: l10n.tripScheduledLoadingAtLabel,
                helperText: l10n.tripDateTimeHelperText,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  _dateTimeValid(value ?? '') ? null : l10n.tripDateTimeInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _scheduledDeliveryController,
              decoration: InputDecoration(
                labelText: l10n.tripScheduledDeliveryAtLabel,
                helperText: l10n.tripDateTimeHelperText,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  _dateTimeValid(value ?? '') ? null : l10n.tripDateTimeInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _actualLoadingController,
              decoration: InputDecoration(
                labelText: l10n.tripActualLoadingAtLabel,
                helperText: l10n.tripDateTimeHelperText,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  _dateTimeValid(value ?? '') ? null : l10n.tripDateTimeInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _actualDeliveryController,
              decoration: InputDecoration(
                labelText: l10n.tripActualDeliveryAtLabel,
                helperText: l10n.tripDateTimeHelperText,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  _dateTimeValid(value ?? '') ? null : l10n.tripDateTimeInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
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
