import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../mappers/auth_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AuthUser>> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.register(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );

      return Success(userModel.toEntity());
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(code: error.statusCode ?? 'auth_error', message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      return Success(userModel.toEntity());
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(code: error.statusCode ?? 'auth_error', message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Success<void>(null);
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(code: error.statusCode ?? 'auth_error', message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      return Success(userModel?.toEntity());
    } on AuthException catch (error) {
      return FailureResult(
        AuthFailure(code: error.statusCode ?? 'auth_error', message: error.message),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
