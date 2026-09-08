part of 'fleet_asset_cards.dart';

String _dateOnlyOrEmpty(BuildContext context, BusinessDate? value) {
  if (value == null) return context.l10n.emptyValue;
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _numberText(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
