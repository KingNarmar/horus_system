import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../../domain/services/driver_image_upload_validator.dart';
import 'driver_form_date_helpers.dart';
import 'driver_form_image_picker_tile.dart';

part 'driver_form_content.dart';
part 'driver_form_image_actions.dart';
part 'driver_form_submission.dart';

class DriverFormData {
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final DriverImageUploadSet? imageUploads;
  final String? notes;

  const DriverFormData({
    required this.fullName,
    this.phone,
    this.nationalId,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.imageUploads,
    this.notes,
  });
}

class DriverFormDialog extends StatefulWidget {
  final Driver? driver;
  final Future<Failure?> Function(DriverFormData data) onSubmit;

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
  final _imagePicker = ImagePicker();
  SelectedDriverImage? _profileImage;
  SelectedDriverImage? _licenseFrontImage;
  SelectedDriverImage? _licenseBackImage;
  SelectedDriverImage? _nationalIdFrontImage;
  SelectedDriverImage? _nationalIdBackImage;
  final _imageUploadValidator = const DriverImageUploadValidator();
  Failure? _imageSelectionFailure;
  DriverImageTarget? _imageSelectionFailureTarget;
  Failure? _submissionFailure;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    _selectedLicenseExpiryDate = driver?.licenseExpiryDate;
    _nameController = TextEditingController(text: driver?.fullName ?? '');
    _phoneController = TextEditingController(text: driver?.phone ?? '');
    _nationalIdController = TextEditingController(
      text: driver?.nationalId ?? '',
    );
    _licenseNumberController = TextEditingController(
      text: driver?.licenseNumber ?? '',
    );
    _licenseExpiryController = TextEditingController(
      text: _selectedLicenseExpiryDate == null
          ? ''
          : driverFormDateOnly(_selectedLicenseExpiryDate!),
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
      title: Text(
        widget.driver == null ? l10n.addDriverButton : l10n.editDriverButton,
      ),
      content: SizedBox(width: 520, child: _content(context)),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _isSubmitting || _hasBlockingImageFailure ? null : _submit,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  void _setSubmissionFailure(Failure failure) {
    setState(() {
      _isSubmitting = false;
      _submissionFailure = failure;
    });
  }

  void _startSubmitting() {
    setState(() {
      _isSubmitting = true;
      _imageSelectionFailure = null;
      _imageSelectionFailureTarget = null;
      _submissionFailure = null;
    });
  }

  void _setSelectedImage(
    DriverImageTarget target,
    SelectedDriverImage selected,
  ) {
    setState(() {
      _imageSelectionFailure = null;
      _imageSelectionFailureTarget = null;
      _submissionFailure = null;
      switch (target) {
        case DriverImageTarget.profile:
          _profileImage = selected;
        case DriverImageTarget.licenseFront:
          _licenseFrontImage = selected;
        case DriverImageTarget.licenseBack:
          _licenseBackImage = selected;
        case DriverImageTarget.nationalIdFront:
          _nationalIdFrontImage = selected;
        case DriverImageTarget.nationalIdBack:
          _nationalIdBackImage = selected;
      }
    });
  }

  void _setImageSelectionFailure(DriverImageTarget target, Failure failure) {
    setState(() {
      _imageSelectionFailure = failure;
      _imageSelectionFailureTarget = target;
      _submissionFailure = null;
    });
  }

  void _closeIfMounted() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickLicenseExpiryDate() async {
    final today = driverFormDateOnlyValue(DateTime.now());
    final currentSelection = _selectedLicenseExpiryDate == null
        ? null
        : driverFormDateOnlyValue(_selectedLicenseExpiryDate!);
    final initialDate =
        currentSelection == null || currentSelection.isBefore(today)
        ? today
        : currentSelection;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: driverLicenseExpiryFirstDate(today),
      lastDate: driverLicenseExpiryLastDate(today),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedLicenseExpiryDate = driverFormDateOnlyValue(pickedDate);
      _licenseExpiryController.text = driverFormDateOnly(pickedDate);
    });
  }

  void _clearLicenseExpiryDate() {
    setState(() {
      _selectedLicenseExpiryDate = null;
      _licenseExpiryController.clear();
    });
  }

  bool get _hasBlockingImageFailure =>
      _imageSelectionFailure != null && _imageSelectionFailureTarget != null;

  bool get _isLicenseExpiryDateValid {
    final selectedDate = _selectedLicenseExpiryDate;
    if (selectedDate == null) return true;
    return !driverFormDateOnlyValue(
      selectedDate,
    ).isBefore(driverFormDateOnlyValue(DateTime.now()));
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
