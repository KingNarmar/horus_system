import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../localization/trips_localizations_x.dart';

class TripStatusUpdateDialog extends StatefulWidget {
  final TripEntity trip;
  final Future<void> Function(TripStatus status, String? notes) onSubmit;

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

    setState(() => _isSubmitting = true);

    await widget.onSubmit(
      status,
      _optional(_notesController.text),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nextStatuses = widget.trip.status.allowedNextStatuses;

    return AlertDialog(
      title: Text(l10n.tripUpdateStatusTitle(widget.trip.displayName)),
      content: SizedBox(
        width: 420,
        child: nextStatuses.isEmpty
            ? Text(l10n.tripNoAvailableStatusActions)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        : (status) => setState(() => _selectedStatus = status),
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
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
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