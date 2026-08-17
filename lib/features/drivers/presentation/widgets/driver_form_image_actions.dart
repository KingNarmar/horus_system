part of 'driver_form_dialog.dart';

extension _DriverFormImageActions on _DriverFormDialogState {
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

    _setSelectedImage(target, selected);
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
    _setImageSelectionFailure(target, failure);
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
