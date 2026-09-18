part of 'trip_form_dialog.dart';

String? _validSelectedValue(String? value, List<TripLookupOption> options) {
  if (value == null || value.trim().isEmpty) return null;

  final exists = options.any((option) => option.id == value);
  return exists ? value : null;
}

String? _optionalSelected(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _optional(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

bool _quantityValid(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;

  final quantity = QuantityTons.tryParse(_normalizeDecimalInput(text));
  return quantity != null && quantity.isPositive;
}

bool _moneyInputValid(
  String value,
  CurrencyConfiguration? financialConfiguration,
) {
  final text = value.trim();
  if (text.isEmpty) return true;

  final configuration = financialConfiguration;
  if (configuration == null) return false;

  return _TripFormDialogState._moneyInputParser.tryParseMinorUnits(
        _normalizeDecimalInput(text),
        fractionDigits: configuration.fractionDigits,
      ) !=
      null;
}

String _normalizeDecimalInput(String value) {
  return value.trim().replaceAll(',', '.');
}

String _formatQuantityInput(QuantityTons? value) {
  if (value == null) return '';
  return value.toDecimalString().replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatMoneyInput(Money? value, CurrencyConfiguration? configuration) {
  if (value == null || configuration == null) return '';
  return _TripFormDialogState._moneyCodec.encodeNonNegative(
    value,
    configuration: configuration,
  );
}
