import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../repositories/company_context_repository.dart';

class SelectCurrentCompanyParams {
  final String companyId;

  const SelectCurrentCompanyParams({required this.companyId});
}

class SelectCurrentCompanyUseCase
    implements UseCase<CurrentCompanyContext, SelectCurrentCompanyParams> {
  final CompanyContextRepository _repository;

  const SelectCurrentCompanyUseCase(this._repository);

  @override
  Future<Result<CurrentCompanyContext>> call(
    SelectCurrentCompanyParams params,
  ) {
    final companyId = params.companyId.trim();

    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult<CurrentCompanyContext>(
          ValidationFailure(
            code: FailureCodes.validationCompanyContextRequired,
            message: 'Company context is required.',
          ),
        ),
      );
    }

    return _repository.selectCompany(companyId);
  }
}
