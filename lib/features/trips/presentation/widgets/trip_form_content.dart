part of 'trip_form_dialog.dart';

extension _TripFormDialogContent on _TripFormDialogState {
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
}
