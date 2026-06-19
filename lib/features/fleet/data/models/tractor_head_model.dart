class TractorHeadModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final DateTime? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String status;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TractorHeadModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.status,
    required this.isActive,
    this.licenseExpiryDate,
    this.expectedFuelConsumption,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory TractorHeadModel.fromMap(Map<String, dynamic> map) {
    return TractorHeadModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      plateNumber: map['plate_number'] as String,
      licenseExpiryDate: _toDateTime(map['license_expiry_date']),
      expectedFuelConsumption: _toDouble(map['expected_fuel_consumption']),
      status: map['status'] as String? ?? 'available',
      notes: map['notes'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
