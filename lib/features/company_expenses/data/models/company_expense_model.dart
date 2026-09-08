import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../constants/company_expense_db_fields.dart';

class CompanyExpenseModel {
  final String id;
  final String companyId;
  final String categoryId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? tripId;
  final double amount;
  final BusinessDate expenseDate;
  final String? referenceNumber;
  final String? notes;
  final bool isVoided;
  final DateTime? voidedAt;
  final String? voidedBy;
  final String? voidReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyExpenseModel({
    required this.id,
    required this.companyId,
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.isVoided,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.tripId,
    this.referenceNumber,
    this.notes,
    this.voidedAt,
    this.voidedBy,
    this.voidReason,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyExpenseModel.fromMap(Map<String, dynamic> map) {
    return CompanyExpenseModel(
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      categoryId: map[CompanyExpenseDbFields.categoryId] as String,
      driverId: map[CompanyExpenseDbFields.driverId] as String?,
      tractorHeadId: map[CompanyExpenseDbFields.tractorHeadId] as String?,
      trailerId: map[CompanyExpenseDbFields.trailerId] as String?,
      tripId: map[CompanyExpenseDbFields.tripId] as String?,
      amount: _amountFrom(map[CompanyExpenseDbFields.amount]),
      expenseDate: DbDate.decode(map[CompanyExpenseDbFields.expenseDate]),
      referenceNumber: map[CompanyExpenseDbFields.referenceNumber] as String?,
      notes: map[CompanyExpenseDbFields.notes] as String?,
      isVoided: map[CompanyExpenseDbFields.isVoided] as bool? ?? false,
      voidedAt: _optionalTimestamp(map[CompanyExpenseDbFields.voidedAt]),
      voidedBy: map[CompanyExpenseDbFields.voidedBy] as String?,
      voidReason: map[CompanyExpenseDbFields.voidReason] as String?,
      createdAt: _optionalTimestamp(map[DbCommonFields.createdAt]),
      updatedAt: _optionalTimestamp(map[DbCommonFields.updatedAt]),
    );
  }

  static double _amountFrom(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _optionalTimestamp(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
