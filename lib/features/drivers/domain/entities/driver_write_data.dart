class DriverWriteData {
  final String companyId;
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? profileImagePath;
  final String? licenseImagePath;
  final String? licenseBackImagePath;
  final String? nationalIdImagePath;
  final String? nationalIdBackImagePath;
  final String? notes;

  const DriverWriteData({
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
  });
}
