import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/billable_trip.dart';
import '../cubit/invoice_draft_form_input.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceDraftDialog extends StatefulWidget {
  final List<BillableTrip> billableTrips;
  final int currencyFractionDigits;
  final Future<bool> Function(InvoiceDraftFormInput input) onSubmit;

  const InvoiceDraftDialog({
    required this.billableTrips,
    required this.currencyFractionDigits,
    required this.onSubmit,
    super.key,
  });

  @override
  State<InvoiceDraftDialog> createState() => _InvoiceDraftDialogState();
}

final class _InvoiceDraftDialogState extends State<InvoiceDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  String? _tripId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    return AlertDialog(
      title: Text(strings.createDraftTitle),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tripId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: strings.trip,
                  border: const OutlineInputBorder(),
                ),
                hint: Text(strings.selectTrip),
                items: widget.billableTrips
                    .map((trip) {
                      return DropdownMenuItem<String>(
                        value: trip.id,
                        child: Text(_tripLabel(context, trip)),
                      );
                    })
                    .toList(growable: false),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _tripId = value),
                validator: (value) {
                  return value == null || value.trim().isEmpty
                      ? strings.tripRequired
                      : null;
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
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
          label: Text(_isSubmitting ? strings.savingDraft : strings.saveDraft),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    final tripId = _tripId;
    if (tripId == null) return;

    final trip = widget.billableTrips.firstWhere((item) => item.id == tripId);
    setState(() => _isSubmitting = true);
    final saved = await widget.onSubmit(
      InvoiceDraftFormInput.fromBillableTrip(
        trip,
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

  String _tripLabel(BuildContext context, BillableTrip trip) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final reference = trip.loadingOrderNumber ?? trip.waybillNumber ?? trip.id;
    final amount = formatInvoiceMoney(
      trip.freightAmount,
      fractionDigits: widget.currencyFractionDigits,
      localeName: localeName,
    );
    return context.invoicesL10n.tripOption(reference, amount);
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
