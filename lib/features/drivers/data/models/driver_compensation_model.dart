import '../constants/driver_compensation_db_fields.dart';

final class DriverCompensationModel {
  final String id;
  final String companyId;
  final String driverId;
  final int amountMinorUnits;
  final String currencyCode;
  final int currencyFractionDigits;
  final String effectiveFrom;
  final String? effectiveTo;
  final String? contractReference;
  final String? contractDocumentReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverCompensationModel({
    required this.id,
    required this.companyId,
    required this.driverId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.currencyFractionDigits,
    required this.effectiveFrom,
    this.effectiveTo,
    this.contractReference,
    this.contractDocumentReference,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverCompensationModel.fromMap(Map<String, dynamic> map) {
    return DriverCompensationModel(
      id: map[DriverCompensationDbFields.id] as String,
      companyId: map[DriverCompensationDbFields.companyId] as String,
      driverId: map[DriverCompensationDbFields.driverId] as String,
      amountMinorUnits: _toInt(
        map[DriverCompensationDbFields.amountMinorUnits],
      ),
      currencyCode: map[DriverCompensationDbFields.currencyCode] as String,
      currencyFractionDigits: _toInt(
        map[DriverCompensationDbFields.currencyFractionDigits],
      ),
      effectiveFrom: map[DriverCompensationDbFields.effectiveFrom].toString(),
      effectiveTo: map[DriverCompensationDbFields.effectiveTo]?.toString(),
      contractReference:
          map[DriverCompensationDbFields.contractReference] as String?,
      contractDocumentReference:
          map[DriverCompensationDbFields.contractDocumentReference] as String?,
      createdAt: _toDateTime(map[DriverCompensationDbFields.createdAt]),
      updatedAt: _toDateTime(map[DriverCompensationDbFields.updatedAt]),
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
