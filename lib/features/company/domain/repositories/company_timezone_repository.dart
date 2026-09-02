import '../../../../core/utils/result.dart';
import '../entities/company.dart';
import '../value_objects/company_timezone.dart';

abstract class CompanyTimezoneRepository {
  Future<Result<List<CompanyTimezone>>> getTimezoneOptions();

  Future<Result<Company>> updateBusinessTimezone({
    required String companyId,
    required CompanyTimezone businessTimezone,
  });
}
