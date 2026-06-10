import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUseCase _registerUseCase;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthCubit({
    required RegisterUseCase registerUseCase,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _registerUseCase = registerUseCase,
        _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthInitial());

  Future<void> checkCurrentUser() async {
    emit(const AuthLoading());

    final result = await _getCurrentUserUseCase(const NoParams());

    result.when(
      success: (user) {
        if (user == null) {
          emit(const AuthUnauthenticated());
          return;
        }

        emit(AuthAuthenticated(user));
      },
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _registerUseCase(
      RegisterParams(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      ),
    );

    result.when(
      success: (user) => emit(AuthAuthenticated(user)),
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.when(
      success: (user) => emit(AuthAuthenticated(user)),
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }

  Future<void> logout() async {
    emit(const AuthLoading());

    final result = await _logoutUseCase(const NoParams());

    result.when(
      success: (_) => emit(const AuthUnauthenticated()),
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }
}
