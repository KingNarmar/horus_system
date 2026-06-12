class DriverModel {
  final String id;
  final String companyId;
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverModel({
    required this.id,
    required this.companyId,
    required this.fullName,
    this.phone,
    this.nationalId,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      nationalId: map['national_id'] as String?,
      licenseNumber: map['license_number'] as String?,
      licenseExpiryDate: _toDateTime(map['license_expiry_date']),
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
}
