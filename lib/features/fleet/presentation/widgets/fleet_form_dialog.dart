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
  final String? notes;

  const FleetFormData({
    required this.plateNumber,
    required this.status,
    this.licenseExpiryDate,
    this.notes,
  });
}

class FleetFormDialog extends StatefulWidget {
  final String title;
  final String? initialPlateNumber;
  final VehicleStatus initialStatus;
  final DateTime? initialLicenseExpiryDate;
  final String? initialNotes;
  final String notesLabel;
  final Future<void> Function(FleetFormData data) onSubmit;

  const FleetFormDialog({
    required this.title,
    required this.initialStatus,
    required this.notesLabel,
    required this.onSubmit,
    this.initialPlateNumber,
    this.initialLicenseExpiryDate,
    this.initialNotes,
    super.key,
  });

  @override
  State<FleetFormDialog> createState() => _FleetFormDialogState();
}

class _FleetFormDialogState extends State<FleetFormDialog> {
  static const _operationalStatuses = [
    VehicleStatus.available,
    VehicleStatus.onTrip,
    VehicleStatus.loading,
    VehicleStatus.unloading,
    VehicleStatus.maintenance,
    VehicleStatus.stopped,
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _licenseExpiryController;
  late final TextEditingController _notesController;
  late VehicleStatus _selectedStatus;
  DateTime? _selectedLicenseExpiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _operationalStatuses.contains(widget.initialStatus) ? widget.initialStatus : VehicleStatus.available;
    _selectedLicenseExpiryDate = widget.initialLicenseExpiryDate;
    _plateController = TextEditingController(text: widget.initialPlateNumber ?? '');
    _licenseExpiryController = TextEditingController(
      text: _selectedLicenseExpiryDate == null ? '' : _dateOnly(_selectedLicenseExpiryDate!),
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _plateController.dispose();
    _licenseExpiryController.dispose();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.plateNumberLabel),
                  validator: (value) => value == null || value.trim().isEmpty ? l10n.plateNumberRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<VehicleStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(labelText: l10n.vehicleStatusLabel),
                  items: _operationalStatuses
                      .map((status) => DropdownMenuItem(value: status, child: Text(l10n.vehicleStatusText(status))))
                      .toList(),
                  onChanged: _isSubmitting ? null : (value) => setState(() => _selectedStatus = value ?? VehicleStatus.available),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _licenseExpiryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.vehicleLicenseExpiryDateLabel,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_licenseExpiryController.text.isNotEmpty)
                          IconButton(
                            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                            icon: const Icon(AppIcons.clear),
                            onPressed: _isSubmitting ? null : _clearLicenseExpiryDate,
                          ),
                        IconButton(
                          tooltip: l10n.vehicleLicenseExpiryDateLabel,
                          icon: const Icon(AppIcons.calendar),
                          onPressed: _isSubmitting ? null : _pickLicenseExpiryDate,
                        ),
                      ],
                    ),
                  ),
                  onTap: _isSubmitting ? null : _pickLicenseExpiryDate,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: widget.notesLabel),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: _isSubmitting ? null : _submit, child: Text(l10n.saveButton)),
      ],
    );
  }

  Future<void> _pickLicenseExpiryDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedLicenseExpiryDate == null || _selectedLicenseExpiryDate!.isBefore(today) ? today : _selectedLicenseExpiryDate!,
      firstDate: DateTime(today.year - 5, today.month, today.day),
      lastDate: DateTime(today.year + 20, today.month, today.day),
    );
    if (pickedDate == null || !mounted) return;
    setState(() {
      _selectedLicenseExpiryDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _licenseExpiryController.text = _dateOnly(pickedDate);
    });
  }

  void _clearLicenseExpiryDate() {
    setState(() {
      _selectedLicenseExpiryDate = null;
      _licenseExpiryController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await widget.onSubmit(
      FleetFormData(
        plateNumber: _plateController.text.trim().toUpperCase(),
        status: _selectedStatus,
        licenseExpiryDate: _selectedLicenseExpiryDate,
        notes: _optional(_notesController.text),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
