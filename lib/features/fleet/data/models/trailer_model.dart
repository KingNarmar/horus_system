import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';

class TrailerModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final BusinessDate? licenseExpiryDate;
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
      licenseExpiryDate: DbDate.decodeNullable(
        map['license_expiry_date'],
        field: 'license_expiry_date',
      ),
      status: map['status'] as String? ?? 'available',
      technicalNotes: map['technical_notes'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DbTimestamp.decodeNullable(
        map['created_at'],
        field: 'created_at',
      ),
      updatedAt: DbTimestamp.decodeNullable(
        map['updated_at'],
        field: 'updated_at',
      ),
    );
  }
}
