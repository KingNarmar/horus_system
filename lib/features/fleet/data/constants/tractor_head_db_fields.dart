abstract class TractorHeadDbFields {
  static const tableName = 'tractor_heads';

  static const plateNumber = 'plate_number';
  static const licenseExpiryDate = 'license_expiry_date';
  static const status = 'status';
  static const notes = 'notes';

  static const allColumns =
      'id, company_id, plate_number, license_expiry_date, status, notes, is_active, created_at, updated_at';
}
