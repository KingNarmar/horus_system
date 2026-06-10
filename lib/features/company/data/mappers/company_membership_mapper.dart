import '../../domain/entities/company_membership.dart';
import '../../domain/entities/current_company_context.dart';
import 'company_mapper.dart';
import '../models/company_membership_model.dart';

extension CompanyMembershipModelMapper on CompanyMembershipModel {
  CompanyMembership toEntity() {
    return CompanyMembership(
      company: company.toEntity(),
      role: role,
      isActive: isActive,
    );
  }

  CurrentCompanyContext toCurrentCompanyContext() {
    return CurrentCompanyContext(company: company.toEntity(), role: role);
  }
}
