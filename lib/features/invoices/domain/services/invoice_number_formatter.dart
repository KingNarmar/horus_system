import '../value_objects/invoice_number.dart';

final class InvoiceNumberFormatter {
  static final RegExp _prefixPattern = RegExp(r'^[A-Z][A-Z0-9-]{0,15}$');

  const InvoiceNumberFormatter();

  InvoiceNumber? format({
    required String prefix,
    required int year,
    required int sequence,
  }) {
    final normalizedPrefix = prefix.trim().toUpperCase();
    if (!_prefixPattern.hasMatch(normalizedPrefix)) return null;
    if (year < 1 || year > 9999 || sequence < 1 || sequence > 999999) {
      return null;
    }

    final value =
        '$normalizedPrefix-${year.toString().padLeft(4, '0')}-'
        '${sequence.toString().padLeft(6, '0')}';
    return InvoiceNumber.tryParse(value);
  }
}
