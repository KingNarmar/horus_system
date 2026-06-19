class TrailerModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final DateTime? licenseExpiryDate;
  final String status;
  final String? technicalNotes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TrailerModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.status,
    required this.isActive,
    this.licenseExpiryDate,
    this.technicalNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory TrailerModel.fromMap(Map<String, dynamic> map) {
    return TrailerModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      plateNumber: map['plate_number'] as String,
      licenseExpiryDate: _toDateTime(map['license_expiry_date']),
      status: map['status'] as String? ?? 'available',
      technicalNotes: map['technical_notes'] as String?,
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
