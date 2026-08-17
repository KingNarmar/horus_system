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
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.driverNameRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: l10n.phoneLabel),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nationalIdController,
                  decoration: InputDecoration(labelText: l10n.nationalIdLabel),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: InputDecoration(
                    labelText: l10n.licenseNumberLabel,
                  ),
                ),
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
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).deleteButtonTooltip,
                            icon: const Icon(AppIcons.clear),
                            onPressed: _isSubmitting
                                ? null
                                : _clearLicenseExpiryDate,
                          ),
                        IconButton(
                          tooltip: l10n.licenseExpiryDateLabel,
                          icon: const Icon(AppIcons.calendar),
                          onPressed: _isSubmitting
                              ? null
                              : _pickLicenseExpiryDate,
                        ),
                      ],
                    ),
                  ),
                  onTap: _isSubmitting ? null : _pickLicenseExpiryDate,
                  validator: (_) => _isLicenseExpiryDateValid
                      ? null
                      : l10n.licenseExpiryDateMustBeFuture,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.notesLabel),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                DriverFormImagePickerTile(
                  label: l10n.driverProfileImageLabel,
                  existingPath: widget.driver?.profileImagePath,
                  selectedImage: _profileImage,
                  failureText: _imageFailureText(
                    l10n,
                    DriverImageTarget.profile,
                  ),
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: DriverImageTarget.profile,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: canUseDriverImageCamera
                      ? () => _pickImage(
                          target: DriverImageTarget.profile,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DriverFormImagePickerTile(
                  label: l10n.driverLicenseFrontImageLabel,
                  existingPath: widget.driver?.licenseImagePath,
                  selectedImage: _licenseFrontImage,
                  failureText: _imageFailureText(
                    l10n,
                    DriverImageTarget.licenseFront,
                  ),
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: DriverImageTarget.licenseFront,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: canUseDriverImageCamera
                      ? () => _pickImage(
                          target: DriverImageTarget.licenseFront,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DriverFormImagePickerTile(
                  label: l10n.driverLicenseBackImageLabel,
                  existingPath: widget.driver?.licenseBackImagePath,
                  selectedImage: _licenseBackImage,
                  failureText: _imageFailureText(
                    l10n,
                    DriverImageTarget.licenseBack,
                  ),
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: DriverImageTarget.licenseBack,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: canUseDriverImageCamera
                      ? () => _pickImage(
                          target: DriverImageTarget.licenseBack,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DriverFormImagePickerTile(
                  label: l10n.driverNationalIdFrontImageLabel,
                  existingPath: widget.driver?.nationalIdImagePath,
                  selectedImage: _nationalIdFrontImage,
                  failureText: _imageFailureText(
                    l10n,
                    DriverImageTarget.nationalIdFront,
                  ),
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: DriverImageTarget.nationalIdFront,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: canUseDriverImageCamera
                      ? () => _pickImage(
                          target: DriverImageTarget.nationalIdFront,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DriverFormImagePickerTile(
                  label: l10n.driverNationalIdBackImageLabel,
                  existingPath: widget.driver?.nationalIdBackImagePath,
                  selectedImage: _nationalIdBackImage,
                  failureText: _imageFailureText(
                    l10n,
                    DriverImageTarget.nationalIdBack,
                  ),
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: DriverImageTarget.nationalIdBack,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: canUseDriverImageCamera
                      ? () => _pickImage(
                          target: DriverImageTarget.nationalIdBack,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                if (_submissionFailure != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.localizedErrorMessage(_submissionFailure!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hasBlockingImageFailure) return;
    setState(() {
      _isSubmitting = true;
      _imageSelectionFailure = null;
      _imageSelectionFailureTarget = null;
      _submissionFailure = null;
    });
    final failure = await widget.onSubmit(
      DriverFormData(
        fullName: _nameController.text,
        phone: _optional(_phoneController.text),
        nationalId: _optional(_nationalIdController.text),
        licenseNumber: _optional(_licenseNumberController.text),
        licenseExpiryDate: _selectedLicenseExpiryDate == null
            ? null
            : driverFormDateOnlyValue(_selectedLicenseExpiryDate!),
        imageUploads: DriverImageUploadSet(
          profileImage: _profileImage?.file,
          licenseFrontImage: _licenseFrontImage?.file,
          licenseBackImage: _licenseBackImage?.file,
          nationalIdFrontImage: _nationalIdFrontImage?.file,
          nationalIdBackImage: _nationalIdBackImage?.file,
        ),
        notes: _optional(_notesController.text),
      ),
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _isSubmitting = false;
        _submissionFailure = failure;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

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

  Future<void> _pickImage({
    required DriverImageTarget target,
    required ImageSource source,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final selected = SelectedDriverImage(
      displayName: picked.name,
      file: DriverImageFile(
        bytes: bytes,
        fileName: picked.name,
        mimeType: picked.mimeType,
      ),
    );
    final imageFailure = _imageUploadValidator.validateImage(selected.file);
    if (imageFailure != null) {
      await _showImageFailure(target, imageFailure);
      return;
    }

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

  String? _imageFailureText(AppLocalizations l10n, DriverImageTarget target) {
    if (_imageSelectionFailureTarget != target ||
        _imageSelectionFailure == null) {
      return null;
    }
    return l10n.localizedErrorMessage(_imageSelectionFailure!);
  }

  Future<void> _showImageFailure(
    DriverImageTarget target,
    Failure failure,
  ) async {
    final l10n = context.l10n;
    final message = l10n.localizedErrorMessage(failure);
    setState(() {
      _imageSelectionFailure = failure;
      _imageSelectionFailureTarget = target;
      _submissionFailure = null;
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.driverImageSelectionFailedTitle),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.okButton),
          ),
        ],
      ),
    );
  }
}
