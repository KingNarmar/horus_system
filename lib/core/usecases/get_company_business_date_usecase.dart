import '../domain/services/company_business_date_provider.dart';
import '../domain/value_objects/business_date.dart';
import '../utils/result.dart';
import 'usecase.dart';

class GetCompanyBusinessDateParams {
  final String companyId;

  const GetCompanyBusinessDateParams({required this.companyId});
}

class GetCompanyBusinessDateUseCase
    implements UseCase<BusinessDate, GetCompanyBusinessDateParams> {
  final CompanyBusinessDateProvider _provider;

  const GetCompanyBusinessDateUseCase(this._provider);

  @override
  Future<Result<BusinessDate>> call(GetCompanyBusinessDateParams params) {
    return _provider.getBusinessDate(companyId: params.companyId);
  }
}
