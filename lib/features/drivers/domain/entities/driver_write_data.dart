class DriverWriteData {
  final String companyId;
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? notes;

  const DriverWriteData({
    required this.companyId,
    required this.fullName,
    this.phone,
    this.nationalId,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.notes,
  });
}
