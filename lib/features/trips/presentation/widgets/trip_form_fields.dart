part of 'trip_form_dialog.dart';

extension _TripFormFields on _TripFormDialogState {
  Widget _requiredDropdown({
    required String label,
    required String? value,
    required List<TripLookupOption> options,
    required String validatorMessage,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.id,
          child: _dropdownLabel(option.label),
        );
      }).toList(),
      onChanged: _isSubmitting ? null : onChanged,
      validator: (value) {
        return value == null || value.trim().isEmpty ? validatorMessage : null;
      },
    );
  }

  Widget _optionalDropdown({
    required String label,
    required String? value,
    required List<TripLookupOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    final l10n = context.l10n;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: _dropdownLabel(l10n.tripOptionalNone),
        ),
        ...options.map((option) {
          return DropdownMenuItem<String>(
            value: option.id,
            child: _dropdownLabel(option.label),
          );
        }),
      ],
      onChanged: _isSubmitting
          ? null
          : (value) => onChanged(value == null || value.isEmpty ? null : value),
    );
  }

  Widget _dropdownLabel(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
