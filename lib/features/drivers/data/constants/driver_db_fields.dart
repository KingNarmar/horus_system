abstract class DriverDbFields {
  static const tableName = 'drivers';

  static const fullName = 'full_name';
  static const phone = 'phone';
  static const nationalId = 'national_id';
  static const licenseNumber = 'license_number';
  static const licenseExpiryDate = 'license_expiry_date';
  static const notes = 'notes';

  static const allColumns =
      'id, company_id, full_name, phone, national_id, license_number, license_expiry_date, notes, is_active, created_at, updated_at';
}
