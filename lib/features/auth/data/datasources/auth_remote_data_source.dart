import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<AuthUserModel?> getCurrentUser();
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseAuthRemoteDataSource(this._client);

  @override
  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw AuthException('Login failed. No user returned.');
    }

    return _toModel(user);
  }

  @override
  Future<void> logout() {
    return _client.auth.signOut();
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _toModel(user);
  }

  AuthUserModel _toModel(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};

    return AuthUserModel(
      id: user.id,
      email: user.email,
      phone: user.phone,
      fullName: _readStringMetadata(metadata, 'full_name') ??
          _readStringMetadata(metadata, 'name'),
      isEmailConfirmed: user.emailConfirmedAt != null,
    );
  }

  String? _readStringMetadata(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }
}
