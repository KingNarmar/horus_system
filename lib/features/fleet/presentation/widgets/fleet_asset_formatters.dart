part of 'fleet_asset_cards.dart';

String _dateOnlyOrEmpty(BuildContext context, BusinessDate? value) {
  return FleetBusinessDateFormatter.formatOrFallback(
    context,
    value,
    fallback: context.l10n.emptyValue,
  );
}

String _numberText(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
