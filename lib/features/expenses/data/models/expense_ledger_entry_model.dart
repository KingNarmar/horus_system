final class ExpenseLedgerEntryModel {
  final String id;
  final String companyId;
  final String expenseTypeId;
  final int amountMinorUnits;
  final String currencyCode;
  final int currencyFractionDigits;
  final String expenseDate;
  final String fundingSource;
  final String? tripId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? referenceNumber;
  final String? notes;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseLedgerEntryModel({
    required this.id,
    required this.companyId,
    required this.expenseTypeId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.currencyFractionDigits,
    required this.expenseDate,
    required this.fundingSource,
    required this.isVoided,
    this.tripId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.referenceNumber,
    this.notes,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseLedgerEntryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseLedgerEntryModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      expenseTypeId: map['expense_type_id'] as String,
      amountMinorUnits: _toInt(map['amount_minor_units']),
      currencyCode: map['currency_code'] as String,
      currencyFractionDigits: _toInt(map['currency_fraction_digits']),
      expenseDate: map['expense_date'].toString(),
      fundingSource: map['funding_source'] as String,
      tripId: map['trip_id'] as String?,
      driverId: map['driver_id'] as String?,
      tractorHeadId: map['tractor_head_id'] as String?,
      trailerId: map['trailer_id'] as String?,
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      isVoided: map['is_voided'] as bool? ?? false,
      voidedAt: _toDateTime(map['voided_at']),
      voidedBy: map['voided_by'] as String?,
      voidReason: map['void_reason'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw const FormatException('Invalid integer value.');
    return parsed;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
