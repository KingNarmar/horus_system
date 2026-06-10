import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_permissions.dart';
import '../entities/current_company_context.dart';
import '../policies/company_permission_policy.dart';

class GetCompanyPermissionsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCompanyPermissionsParams({required this.currentCompanyContext});
}

class GetCompanyPermissionsUseCase
    implements UseCase<CompanyPermissions, GetCompanyPermissionsParams> {
  const GetCompanyPermissionsUseCase();

  @override
  Future<Result<CompanyPermissions>> call(
    GetCompanyPermissionsParams params,
  ) async {
    return Success(
      CompanyPermissionPolicy.permissionsFor(params.currentCompanyContext.role),
    );
  }
}
