import '../../utils/result.dart';

abstract interface class CompanyBusinessDateProvider {
  Future<Result<DateTime>> getBusinessDate({required String companyId});
}
