import '../../../../core/data/constants/db_common_fields.dart';

abstract final class CompanyExpenseDbFields {
  static const tableName = 'company_expenses';

  static const categoryId = 'category_id';
  static const driverId = 'driver_id';
  static const tractorHeadId = 'tractor_head_id';
  static const trailerId = 'trailer_id';
  static const tripId = 'trip_id';
  static const amount = 'amount';
  static const expenseDate = 'expense_date';
  static const referenceNumber = 'reference_number';
  static const notes = 'notes';
  static const isVoided = 'is_voided';
  static const voidedAt = 'voided_at';
  static const voidedBy = 'voided_by';
  static const voidReason = 'void_reason';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $categoryId, '
      '$driverId, $tractorHeadId, $trailerId, $tripId, $amount, $expenseDate, '
      '$referenceNumber, $notes, $isVoided, $voidedAt, $voidedBy, $voidReason, '
      '${DbCommonFields.createdAt}, ${DbCommonFields.updatedAt}';
}

abstract final class CompanyExpenseCategoryDbFields {
  static const tableName = 'company_expense_categories';

  static const name = 'name';
  static const code = 'code';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, $name, $code, '
      '${DbCommonFields.isActive}, ${DbCommonFields.createdAt}, '
      '${DbCommonFields.updatedAt}';
}

abstract final class CompanyExpenseLookupDbFields {
  static const driversTableName = 'drivers';
  static const tractorHeadsTableName = 'tractor_heads';
  static const trailersTableName = 'trailers';
  static const tripsTableName = 'trips';

  static const fullName = 'full_name';
  static const plateNumber = 'plate_number';
  static const loadingOrderNumber = 'loading_order_number';
  static const waybillNumber = 'waybill_number';

  static const tripColumns =
      '${DbCommonFields.id}, $loadingOrderNumber, $waybillNumber, '
      '${DbCommonFields.createdAt}';
}
