import '../../domain/entities/auth_user.dart';
import '../models/auth_user_model.dart';

extension AuthUserModelMapper on AuthUserModel {
  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      phone: phone,
      fullName: fullName,
      isEmailConfirmed: isEmailConfirmed,
    );
  }
}
