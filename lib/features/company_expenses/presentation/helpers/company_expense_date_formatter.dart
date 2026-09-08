import '../../../../core/domain/value_objects/business_date.dart';

String formatCompanyExpenseDate(BusinessDate value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
