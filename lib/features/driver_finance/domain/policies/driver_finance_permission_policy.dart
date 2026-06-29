import '../../../company/domain/entities/company_role.dart';

abstract final class DriverFinancePermissionPolicy {
  static bool canViewDriverFinance(CompanyRole role) {
    return true;
  }
}
