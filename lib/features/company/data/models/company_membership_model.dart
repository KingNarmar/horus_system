import '../../domain/entities/company_role.dart';
import '../mappers/company_role_model_mapper.dart';
import 'company_model.dart';

class CompanyMembershipModel {
  final CompanyModel company;
  final CompanyRole role;
  final bool isActive;

  const CompanyMembershipModel({
    required this.company,
    required this.role,
    required this.isActive,
  });

  factory CompanyMembershipModel.fromMap(Map<String, dynamic> map) {
    final companyMap = Map<String, dynamic>.from(map['companies'] as Map);

    return CompanyMembershipModel(
      company: CompanyModel.fromMap(companyMap),
      role: CompanyRoleModelMapper.fromDatabaseValue(map['role'] as String?),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
