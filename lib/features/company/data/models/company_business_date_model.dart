import '../../../../core/data/utils/db_date.dart';
import '../../../../core/domain/value_objects/business_date.dart';

final class CompanyBusinessDateModel {
  final BusinessDate value;

  const CompanyBusinessDateModel(this.value);

  factory CompanyBusinessDateModel.fromValue(Object? rawValue) {
    return CompanyBusinessDateModel(DbDate.decode(rawValue));
  }
}
