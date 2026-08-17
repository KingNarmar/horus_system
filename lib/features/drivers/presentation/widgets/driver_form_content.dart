part of 'driver_form_dialog.dart';

extension _DriverFormContent on _DriverFormDialogState {
  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _identityFields(context),
            const SizedBox(height: AppSpacing.md),
            _documentImageFields(context),
            if (_submissionFailure != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.localizedErrorMessage(_submissionFailure!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _identityFields(BuildContext context) {
    final l10n = context.l10n;

    return Column(
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
          decoration: InputDecoration(labelText: l10n.licenseNumberLabel),
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
                    onPressed: _isSubmitting ? null : _clearLicenseExpiryDate,
                  ),
                IconButton(
                  tooltip: l10n.licenseExpiryDateLabel,
                  icon: const Icon(AppIcons.calendar),
                  onPressed: _isSubmitting ? null : _pickLicenseExpiryDate,
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
      ],
    );
  }

  Widget _documentImageFields(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _documentImageField(
          label: l10n.driverProfileImageLabel,
          existingPath: widget.driver?.profileImagePath,
          selectedImage: _profileImage,
          target: DriverImageTarget.profile,
        ),
        const SizedBox(height: AppSpacing.md),
        _documentImageField(
          label: l10n.driverLicenseFrontImageLabel,
          existingPath: widget.driver?.licenseImagePath,
          selectedImage: _licenseFrontImage,
          target: DriverImageTarget.licenseFront,
        ),
        const SizedBox(height: AppSpacing.md),
        _documentImageField(
          label: l10n.driverLicenseBackImageLabel,
          existingPath: widget.driver?.licenseBackImagePath,
          selectedImage: _licenseBackImage,
          target: DriverImageTarget.licenseBack,
        ),
        const SizedBox(height: AppSpacing.md),
        _documentImageField(
          label: l10n.driverNationalIdFrontImageLabel,
          existingPath: widget.driver?.nationalIdImagePath,
          selectedImage: _nationalIdFrontImage,
          target: DriverImageTarget.nationalIdFront,
        ),
        const SizedBox(height: AppSpacing.md),
        _documentImageField(
          label: l10n.driverNationalIdBackImageLabel,
          existingPath: widget.driver?.nationalIdBackImagePath,
          selectedImage: _nationalIdBackImage,
          target: DriverImageTarget.nationalIdBack,
        ),
      ],
    );
  }

  Widget _documentImageField({
    required String label,
    required String? existingPath,
    required SelectedDriverImage? selectedImage,
    required DriverImageTarget target,
  }) {
    return DriverFormImagePickerTile(
      label: label,
      existingPath: existingPath,
      selectedImage: selectedImage,
      failureText: _imageFailureText(context.l10n, target),
      isSubmitting: _isSubmitting,
      onPickFromFiles: () =>
          _pickImage(target: target, source: ImageSource.gallery),
      onTakePhoto: canUseDriverImageCamera
          ? () => _pickImage(target: target, source: ImageSource.camera)
          : null,
    );
  }
}
