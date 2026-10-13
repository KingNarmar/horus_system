import '../../../utils/result.dart';
import '../entities/company_data_change.dart';

abstract interface class CompanyDataChangesRepository {
  Stream<Result<CompanyDataChange>> watchChanges({required String companyId});
}
