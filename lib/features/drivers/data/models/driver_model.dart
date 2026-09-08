import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';

class DriverModel {
  final String id;
  final String companyId;
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final BusinessDate? licenseExpiryDate;
  final String? profileImagePath;
  final String? licenseImagePath;
  final String? licenseBackImagePath;
  final String? nationalIdImagePath;
  final String? nationalIdBackImagePath;
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
    this.profileImagePath,
    this.licenseImagePath,
    this.licenseBackImagePath,
    this.nationalIdImagePath,
    this.nationalIdBackImagePath,
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
      licenseExpiryDate: DbDate.decodeNullable(
        map['license_expiry_date'],
        field: 'license_expiry_date',
      ),
      profileImagePath: map['profile_image_path'] as String?,
      licenseImagePath: map['license_image_path'] as String?,
      licenseBackImagePath: map['license_back_image_path'] as String?,
      nationalIdImagePath: map['national_id_image_path'] as String?,
      nationalIdBackImagePath: map['national_id_back_image_path'] as String?,
      notes: map['notes'] as String?,
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
