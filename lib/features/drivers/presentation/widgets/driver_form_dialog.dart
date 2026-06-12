import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver.dart';
import '../localization/drivers_localizations_x.dart';

class DriverFormData {
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? notes;

  const DriverFormData({
    required this.fullName,
    this.phone,
    this.nationalId,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.notes,
  });
}

class DriverFormDialog extends StatefulWidget {
  final Driver? driver;
  final Future<void> Function(DriverFormData data) onSubmit;

  const DriverFormDialog({required this.onSubmit, this.driver, super.key});

  @override
  State<DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _licenseNumberController;
  late final TextEditingController _licenseExpiryController;
  late final TextEditingController _notesController;
  DateTime? _selectedLicenseExpiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    _selectedLicenseExpiryDate = driver?.licenseExpiryDate;
    _nameController = TextEditingController(text: driver?.fullName ?? '');
    _phoneController = TextEditingController(text: driver?.phone ?? '');
    _nationalIdController = TextEditingController(text: driver?.nationalId ?? '');
    _licenseNumberController = TextEditingController(text: driver?.licenseNumber ?? '');
    _licenseExpiryController = TextEditingController(
      text: _selectedLicenseExpiryDate == null ? '' : _dateOnly(_selectedLicenseExpiryDate!),
    );
    _notesController = TextEditingController(text: driver?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.driver == null ? l10n.addDriverButton : l10n.editDriverButton),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.driverNameLabel),
                  validator: (value) => value == null || value.trim().isEmpty ? l10n.driverNameRequired : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: l10n.phoneLabel)),
                const SizedBox(height: AppSpacing.md),
                TextFormField(controller: _nationalIdController, decoration: InputDecoration(labelText: l10n.nationalIdLabel)),
                const SizedBox(height: AppSpacing.md),
                TextFormField(controller: _licenseNumberController, decoration: InputDecoration(labelText: l10n.licenseNumberLabel)),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _licenseExpiryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.licenseExpiryDateLabel,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_licenseExpiryController.text.isNotEmpty)
                          IconButton(
                            tooltip: l10n.clearButton,
                            icon: const Icon(Icons.close),
                            onPressed: _isSubmitting ? null : _clearLicenseExpiryDate,
                          ),
                        IconButton(
                          tooltip: l10n.licenseExpiryDateLabel,
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: _isSubmitting ? null : _pickLicenseExpiryDate,
                        ),
                      ],
                    ),
                  ),
                  onTap: _isSubmitting ? null : _pickLicenseExpiryDate,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(controller: _notesController, decoration: InputDecoration(labelText: l10n.notesLabel), maxLines: 3),
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
    final initialDate = _selectedLicenseExpiryDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedLicenseExpiryDate = pickedDate;
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
      DriverFormData(
        fullName: _nameController.text,
        phone: _optional(_phoneController.text),
        nationalId: _optional(_nationalIdController.text),
        licenseNumber: _optional(_licenseNumberController.text),
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
