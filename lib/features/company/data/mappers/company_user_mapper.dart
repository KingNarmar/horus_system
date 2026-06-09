import '../../domain/entities/company_user.dart';
import '../models/company_user_model.dart';

extension CompanyUserModelMapper on CompanyUserModel {
  CompanyUser toEntity() {
    return CompanyUser(
      id: id,
      companyId: companyId,
      userId: userId,
      displayName: displayName,
      email: email,
      role: role,
      isActive: isActive,
    );
  }
}
