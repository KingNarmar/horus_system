import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../mappers/auth_user_mapper.dart';
import 'auth_repository_failure_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = AuthRepositoryFailureMapper();

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final userModel = await _remoteDataSource.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );

      return Success(userModel.toEntity());
    });
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      return Success(userModel.toEntity());
    });
  }

  @override
  Future<Result<void>> logout() {
    return _guard(() async {
      await _remoteDataSource.logout();
      return const Success<void>(null);
    });
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() {
    return _guard(() async {
      final userModel = await _remoteDataSource.getCurrentUser();
      return Success(userModel?.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
