class AuthUserModel {
  const AuthUserModel({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.isEmailConfirmed = false,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final bool isEmailConfirmed;
}
