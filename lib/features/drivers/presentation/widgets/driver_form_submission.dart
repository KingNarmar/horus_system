part of 'driver_form_dialog.dart';

extension _DriverFormSubmission on _DriverFormDialogState {
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hasBlockingImageFailure) return;

    _startSubmitting();

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
      _setSubmissionFailure(failure);
      return;
    }

    _closeIfMounted();
  }
}
