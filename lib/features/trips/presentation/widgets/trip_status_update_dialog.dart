import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../helpers/trips_failure_message.dart';
import '../localization/trips_localizations_x.dart';
import '../models/trip_mutation_result.dart';

class TripStatusUpdateDialog extends StatefulWidget {
  final TripEntity trip;
  final Future<TripMutationResult> Function(
    TripStatus status,
    String? notes,
  )
  onSubmit;

  const TripStatusUpdateDialog({
    required this.trip,
    required this.onSubmit,
    super.key,
  });

  @override
  State<TripStatusUpdateDialog> createState() => _TripStatusUpdateDialogState();
}

class _TripStatusUpdateDialogState extends State<TripStatusUpdateDialog> {
  final _notesController = TextEditingController();
  TripStatus? _selectedStatus;
  bool _isSubmitting = false;
  Failure? _submitFailure;

  @override
  void initState() {
    super.initState();
    final nextStatuses = widget.trip.status.allowedNextStatuses;
    _selectedStatus = nextStatuses.isEmpty ? null : nextStatuses.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final status = _selectedStatus;
    if (status == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitFailure = null;
    });

    final result = await widget.onSubmit(
      status,
      _optional(_notesController.text),
    );

    if (!mounted) return;

    if (result is TripMutationSucceeded || result is TripMutationIgnored) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitFailure = (result as TripMutationFailed).failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nextStatuses = widget.trip.status.allowedNextStatuses;

    return AlertDialog(
      title: Text(l10n.tripUpdateStatusTitle(widget.trip.displayName)),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: nextStatuses.isEmpty
            ? Text(l10n.tripNoAvailableStatusActions)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_submitFailure != null) ...[
                    Text(
                      tripsFailureMessage(context, _submitFailure!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    l10n.tripCurrentStatusLine(
                      l10n.tripStatusLabel(widget.trip.status),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<TripStatus>(
                    initialValue: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: l10n.tripNextStatusLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: nextStatuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(l10n.tripStatusLabel(status)),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (status) => setState(() {
                            _selectedStatus = status;
                            _submitFailure = null;
                          }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notesController,
                    enabled: !_isSubmitting,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.tripStatusNotesLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.tripCancelButton),
        ),
        FilledButton(
          onPressed:
              _isSubmitting || nextStatuses.isEmpty || _selectedStatus == null
              ? null
              : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: AppSizes.loadingIndicatorSm,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                  ),
                )
              : Text(l10n.tripSaveButton),
        ),
      ],
    );
  }
}

String? _optional(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return text;
}
