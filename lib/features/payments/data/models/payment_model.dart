import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/payments_db_constants.dart';

final class PaymentModel {
  final String id;
  final String companyId;
  final String invoiceId;
  final String customerId;
  final String paymentMethodId;
  final DateTime paymentDate;
  final int amountMinorUnits;
  final String currencyCode;
  final String? referenceNumber;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.customerId,
    required this.paymentMethodId,
    required this.paymentDate,
    required this.amountMinorUnits,
    required this.currencyCode,
    this.referenceNumber,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: _requiredString(map[DbCommonFields.id], DbCommonFields.id),
      companyId: _requiredString(
        map[DbCommonFields.companyId],
        DbCommonFields.companyId,
      ),
      invoiceId: _requiredString(
        map[PaymentsDbConstants.invoiceId],
        PaymentsDbConstants.invoiceId,
      ),
      customerId: _requiredString(
        map[PaymentsDbConstants.customerId],
        PaymentsDbConstants.customerId,
      ),
      paymentMethodId: _requiredString(
        map[PaymentsDbConstants.paymentMethodId],
        PaymentsDbConstants.paymentMethodId,
      ),
      paymentDate: _requiredDate(
        map[PaymentsDbConstants.paymentDate],
        PaymentsDbConstants.paymentDate,
      ),
      amountMinorUnits: _requiredInt(
        map[PaymentsDbConstants.amountMinorUnits],
        PaymentsDbConstants.amountMinorUnits,
      ),
      currencyCode: _requiredString(
        map[PaymentsDbConstants.currencyCode],
        PaymentsDbConstants.currencyCode,
      ),
      referenceNumber: _optionalString(
        map[PaymentsDbConstants.referenceNumber],
      ),
      notes: _optionalString(map[PaymentsDbConstants.notes]),
      createdBy: _optionalString(map[PaymentsDbConstants.createdBy]),
      createdAt: _requiredDateTime(
        map[DbCommonFields.createdAt],
        DbCommonFields.createdAt,
      ),
    );
  }
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid payment field: $field.');
  }
  return value.trim();
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid payment text.');
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num && value == value.truncate()) return value.toInt();
  throw FormatException('Invalid payment integer field: $field.');
}

DateTime _requiredDate(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) throw FormatException('Invalid payment date: $field.');
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _requiredDateTime(Object? value, String field) {
  final raw = _requiredString(value, field);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Invalid payment timestamp: $field.');
  }
  return parsed;
}
