abstract class TrailerDbFields {
  static const tableName = 'trailers';

  static const plateNumber = 'plate_number';
  static const licenseExpiryDate = 'license_expiry_date';
  static const status = 'status';
  static const technicalNotes = 'technical_notes';

  static const allColumns =
      'id, company_id, plate_number, license_expiry_date, status, technical_notes, is_active, created_at, updated_at';
}
