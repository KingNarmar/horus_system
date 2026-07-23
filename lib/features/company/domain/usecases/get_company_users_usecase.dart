import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_user.dart';
import '../entities/current_company_context.dart';
import '../policies/company_permission_policy.dart';
import '../repositories/company_users_repository.dart';

class GetCompanyUsersParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCompanyUsersParams({required this.currentCompanyContext});
}

class GetCompanyUsersUseCase
    implements UseCase<List<CompanyUser>, GetCompanyUsersParams> {
  final CompanyUsersRepository _repository;

  const GetCompanyUsersUseCase(this._repository);

  @override
  Future<Result<List<CompanyUser>>> call(GetCompanyUsersParams params) {
    final currentCompanyContext = params.currentCompanyContext;
    final canViewUsers = CompanyPermissionPolicy.canViewCompanyUsers(
      currentCompanyContext.role,
    );

    if (!canViewUsers) {
      return Future.value(
        const FailureResult<List<CompanyUser>>(
          PermissionFailure(
            code: FailureCodes.permissionCompanyUsersView,
            message: 'This role cannot view company users.',
          ),
        ),
      );
    }

    return _repository.getCompanyUsers(
      companyId: currentCompanyContext.companyId,
    );
  }
}
