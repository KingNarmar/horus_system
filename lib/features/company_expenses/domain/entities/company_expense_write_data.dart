class CompanyExpenseWriteData {
  final String companyId;
  final String categoryId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? tripId;
  final double amount;
  final DateTime expenseDate;
  final String? referenceNumber;
  final String? notes;

  const CompanyExpenseWriteData({
    required this.companyId,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.tripId,
    this.referenceNumber,
    this.notes,
  });
}
