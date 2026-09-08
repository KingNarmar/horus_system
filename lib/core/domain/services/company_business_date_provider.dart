import '../../utils/result.dart';
import '../value_objects/business_date.dart';

abstract interface class CompanyBusinessDateProvider {
  Future<Result<BusinessDate>> getBusinessDate({required String companyId});
}
