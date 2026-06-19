import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/vehicle_status.dart';
import '../localization/fleet_localizations_x.dart';

class FleetFormData {
  final String plateNumber;
  final VehicleStatus status;
  final DateTime? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String? notes;

  const FleetFormData({required this.plateNumber, required this.status, this.licenseExpiryDate, this.expectedFuelConsumption, this.notes});
}

class FleetFormDialog extends StatefulWidget {
  final String title;
  final String? initialPlateNumber;
  final VehicleStatus initialStatus;
  final DateTime? initialLicenseExpiryDate;
  final double? initialExpectedFuelConsumption;
  final String? initialNotes;
  final String notesLabel;
  final bool showExpectedFuelConsumption;
  final Future<void> Function(FleetFormData data) onSubmit;

  const FleetFormDialog({required this.title, required this.initialStatus, required this.notesLabel, required this.onSubmit, this.initialPlateNumber, this.initialLicenseExpiryDate, this.initialExpectedFuelConsumption, this.initialNotes, this.showExpectedFuelConsumption = false, super.key});

  @override
  State<FleetFormDialog> createState() => _FleetFormDialogState();
}

class _FleetFormDialogState extends State<FleetFormDialog> {
  static const _statuses = [VehicleStatus.available, VehicleStatus.onTrip, VehicleStatus.loading, VehicleStatus.unloading, VehicleStatus.maintenance, VehicleStatus.stopped];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _dateController;
  late final TextEditingController _rateController;
  late final TextEditingController _notesController;
  late VehicleStatus _status;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _status = _statuses.contains(widget.initialStatus) ? widget.initialStatus : VehicleStatus.available;
    _selectedDate = widget.initialLicenseExpiryDate;
    _plateController = TextEditingController(text: widget.initialPlateNumber ?? '');
    _dateController = TextEditingController(text: _selectedDate == null ? '' : _dateOnly(_selectedDate!));
    _rateController = TextEditingController(text: _formatDouble(widget.initialExpectedFuelConsumption));
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _plateController.dispose();
    _dateController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: _plateController, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: l10n.plateNumberLabel), validator: (value) => value == null || value.trim().isEmpty ? l10n.plateNumberRequired : null),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<VehicleStatus>(initialValue: _status, decoration: InputDecoration(labelText: l10n.vehicleStatusLabel), items: _statuses.map((status) => DropdownMenuItem(value: status, child: Text(l10n.vehicleStatusText(status)))).toList(), onChanged: _isSubmitting ? null : (value) => setState(() => _status = value ?? VehicleStatus.available)),
              const SizedBox(height: AppSpacing.md),
              TextFormField(controller: _dateController, readOnly: true, decoration: InputDecoration(labelText: l10n.vehicleLicenseExpiryDateLabel, suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [if (_dateController.text.isNotEmpty) IconButton(icon: const Icon(AppIcons.clear), onPressed: _isSubmitting ? null : _clearDate), IconButton(icon: const Icon(AppIcons.calendar), onPressed: _isSubmitting ? null : _pickDate)])), onTap: _isSubmitting ? null : _pickDate),
              if (widget.showExpectedFuelConsumption) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(controller: _rateController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: l10n.expectedFuelConsumptionLabel), validator: (_) => _rateValid ? null : l10n.expectedFuelConsumptionInvalid),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(controller: _notesController, decoration: InputDecoration(labelText: widget.notesLabel), maxLines: 3),
            ]),
          ),
        ),
      ),
      actions: [TextButton(onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)), FilledButton(onPressed: _isSubmitting ? null : _submit, child: Text(l10n.saveButton))],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _selectedDate ?? now, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 20));
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _dateController.text = _dateOnly(picked);
    });
  }

  void _clearDate() => setState(() {
        _selectedDate = null;
        _dateController.clear();
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await widget.onSubmit(FleetFormData(plateNumber: _plateController.text.trim().toUpperCase(), status: _status, licenseExpiryDate: _selectedDate, expectedFuelConsumption: _parseRate(), notes: _optional(_notesController.text)));
    if (mounted) Navigator.of(context).pop();
  }

  bool get _rateValid => _rateController.text.trim().isEmpty || (_parseRate() != null && _parseRate()! >= 0);
  double? _parseRate() => _rateController.text.trim().isEmpty ? null : double.tryParse(_rateController.text.trim().replaceAll(',', '.'));
  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _formatDouble(double? value) {
  if (value == null) return '';
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
