part of 'fleet_asset_cards.dart';

String _dateOnlyOrEmpty(BuildContext context, DateTime? value) {
  if (value == null) return context.l10n.emptyValue;
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _numberText(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
