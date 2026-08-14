import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_date_constraints.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../localization/drivers_localizations_x.dart';

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
  final _imagePicker = ImagePicker();
  _SelectedDriverImage? _profileImage;
  _SelectedDriverImage? _licenseFrontImage;
  _SelectedDriverImage? _licenseBackImage;
  _SelectedDriverImage? _nationalIdFrontImage;
  _SelectedDriverImage? _nationalIdBackImage;
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
          : _dateOnly(_selectedLicenseExpiryDate!),
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
                _DriverImagePickerTile(
                  label: l10n.driverProfileImageLabel,
                  existingPath: widget.driver?.profileImagePath,
                  selectedImage: _profileImage,
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: _DriverImageTarget.profile,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: _canUseCamera
                      ? () => _pickImage(
                          target: _DriverImageTarget.profile,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _DriverImagePickerTile(
                  label: l10n.driverLicenseFrontImageLabel,
                  existingPath: widget.driver?.licenseImagePath,
                  selectedImage: _licenseFrontImage,
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: _DriverImageTarget.licenseFront,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: _canUseCamera
                      ? () => _pickImage(
                          target: _DriverImageTarget.licenseFront,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _DriverImagePickerTile(
                  label: l10n.driverLicenseBackImageLabel,
                  existingPath: widget.driver?.licenseBackImagePath,
                  selectedImage: _licenseBackImage,
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: _DriverImageTarget.licenseBack,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: _canUseCamera
                      ? () => _pickImage(
                          target: _DriverImageTarget.licenseBack,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _DriverImagePickerTile(
                  label: l10n.driverNationalIdFrontImageLabel,
                  existingPath: widget.driver?.nationalIdImagePath,
                  selectedImage: _nationalIdFrontImage,
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: _DriverImageTarget.nationalIdFront,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: _canUseCamera
                      ? () => _pickImage(
                          target: _DriverImageTarget.nationalIdFront,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _DriverImagePickerTile(
                  label: l10n.driverNationalIdBackImageLabel,
                  existingPath: widget.driver?.nationalIdBackImagePath,
                  selectedImage: _nationalIdBackImage,
                  isSubmitting: _isSubmitting,
                  onPickFromFiles: () => _pickImage(
                    target: _DriverImageTarget.nationalIdBack,
                    source: ImageSource.gallery,
                  ),
                  onTakePhoto: _canUseCamera
                      ? () => _pickImage(
                          target: _DriverImageTarget.nationalIdBack,
                          source: ImageSource.camera,
                        )
                      : null,
                ),
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
          onPressed: _isSubmitting ? null : _submit,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }

  Future<void> _pickLicenseExpiryDate() async {
    final today = _dateOnlyValue(DateTime.now());
    final currentSelection = _selectedLicenseExpiryDate == null
        ? null
        : _dateOnlyValue(_selectedLicenseExpiryDate!);
    final initialDate =
        currentSelection == null || currentSelection.isBefore(today)
        ? today
        : currentSelection;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _driverLicenseExpiryFirstDate(today),
      lastDate: _driverLicenseExpiryLastDate(today),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedLicenseExpiryDate = _dateOnlyValue(pickedDate);
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
        licenseExpiryDate: _selectedLicenseExpiryDate == null
            ? null
            : _dateOnlyValue(_selectedLicenseExpiryDate!),
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
    if (mounted) Navigator.of(context).pop();
  }

  bool get _isLicenseExpiryDateValid {
    final selectedDate = _selectedLicenseExpiryDate;
    if (selectedDate == null) return true;
    return !_dateOnlyValue(
      selectedDate,
    ).isBefore(_dateOnlyValue(DateTime.now()));
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _pickImage({
    required _DriverImageTarget target,
    required ImageSource source,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final selected = _SelectedDriverImage(
      displayName: picked.name,
      file: DriverImageFile(
        bytes: bytes,
        fileName: picked.name,
        mimeType: picked.mimeType,
      ),
    );

    setState(() {
      switch (target) {
        case _DriverImageTarget.profile:
          _profileImage = selected;
        case _DriverImageTarget.licenseFront:
          _licenseFrontImage = selected;
        case _DriverImageTarget.licenseBack:
          _licenseBackImage = selected;
        case _DriverImageTarget.nationalIdFront:
          _nationalIdFrontImage = selected;
        case _DriverImageTarget.nationalIdBack:
          _nationalIdBackImage = selected;
      }
    });
  }
}

enum _DriverImageTarget {
  profile,
  licenseFront,
  licenseBack,
  nationalIdFront,
  nationalIdBack,
}

class _SelectedDriverImage {
  final String displayName;
  final DriverImageFile file;

  const _SelectedDriverImage({required this.displayName, required this.file});
}

class _DriverImagePickerTile extends StatelessWidget {
  final String label;
  final String? existingPath;
  final _SelectedDriverImage? selectedImage;
  final bool isSubmitting;
  final VoidCallback onPickFromFiles;
  final VoidCallback? onTakePhoto;

  const _DriverImagePickerTile({
    required this.label,
    required this.existingPath,
    required this.selectedImage,
    required this.isSubmitting,
    required this.onPickFromFiles,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasExisting = existingPath?.trim().isNotEmpty ?? false;
    final status =
        selectedImage?.displayName ??
        (hasExisting ? l10n.driverImageAlreadyUploaded : l10n.emptyValue);

    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.image),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : onPickFromFiles,
                icon: const Icon(AppIcons.uploadFile),
                label: Text(l10n.driverChooseImageFromFiles),
              ),
              if (onTakePhoto != null)
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onTakePhoto,
                  icon: const Icon(AppIcons.camera),
                  label: Text(l10n.driverTakeImageWithCamera),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

bool get _canUseCamera {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

DateTime _driverLicenseExpiryFirstDate(DateTime today) {
  return DateTime(
    today.year - AppDateConstraints.driverLicenseExpiryPastYears,
    today.month,
    today.day,
  );
}

DateTime _driverLicenseExpiryLastDate(DateTime today) {
  return DateTime(
    today.year + AppDateConstraints.driverLicenseExpiryFutureYears,
    today.month,
    today.day,
  );
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

DateTime _dateOnlyValue(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
