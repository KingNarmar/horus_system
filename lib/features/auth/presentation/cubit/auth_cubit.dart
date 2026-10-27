import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/auth_session_change.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/watch_auth_session_changes_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final RegisterUseCase _registerUseCase;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final WatchAuthSessionChangesUseCase? _watchSessionChangesUseCase;
  StreamSubscription? _sessionSubscription;
  int _operationGeneration = 0;

  AuthCubit({
    required RegisterUseCase registerUseCase,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    WatchAuthSessionChangesUseCase? watchSessionChangesUseCase,
  }) : _registerUseCase = registerUseCase,
       _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _watchSessionChangesUseCase = watchSessionChangesUseCase,
       super(const AuthInitial());

  /// Started by app composition. SDK event ownership stays in Data.
  void startWatchingSession() {
    if (_sessionSubscription != null || _watchSessionChangesUseCase == null) {
      return;
    }
    _sessionSubscription = _watchSessionChangesUseCase(const NoParams()).listen(
      (result) {
        if (isClosed) return;
        final change = result.dataOrNull;
        if (change == null) return;
        switch (change) {
          case AuthSessionChange.signedOut:
            ++_operationGeneration;
            emit(const AuthUnauthenticated());
          case AuthSessionChange.signedIn:
            if (state is AuthInitial || state is AuthUnauthenticated) {
              unawaited(checkCurrentUser());
            }
          case AuthSessionChange.tokenRefreshed:
            final current = state;
            if (current is AuthAuthenticated) {
              emit(
                AuthAuthenticated(
                  current.user,
                  sessionRevision: current.sessionRevision + 1,
                ),
              );
            }
        }
      },
      onError: (Object _, StackTrace _) {
        // Never include SDK errors or token material in logs.
        AppLogger.debug('auth_session_events_unavailable');
      },
    );
  }

  Future<void> checkCurrentUser() async {
    final generation = ++_operationGeneration;
    emit(const AuthLoading());

    final result = await _getCurrentUserUseCase(const NoParams());
    if (!_isCurrent(generation)) return;

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
    final generation = ++_operationGeneration;
    emit(const AuthLoading());

    final result = await _registerUseCase(
      RegisterParams(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      ),
    );
    if (!_isCurrent(generation)) return;

    result.when(
      success: (user) {
        if (!user.isEmailConfirmed) {
          emit(AuthEmailConfirmationRequired(user.email ?? email));
          return;
        }
        emit(AuthAuthenticated(user));
      },
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }

  Future<void> login({required String email, required String password}) async {
    final generation = ++_operationGeneration;
    emit(const AuthLoginSubmitting());

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );
    if (!_isCurrent(generation)) return;

    result.when(
      success: (user) => emit(AuthAuthenticated(user)),
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }

  Future<void> logout() async {
    final generation = ++_operationGeneration;
    emit(const AuthLoading());

    final result = await _logoutUseCase(const NoParams());
    if (!_isCurrent(generation)) return;

    result.when(
      success: (_) => emit(const AuthUnauthenticated()),
      failure: (failure) => emit(AuthFailureState(failure)),
    );
  }

  bool _isCurrent(int generation) =>
      !isClosed && generation == _operationGeneration;

  @override
  Future<void> close() async {
    ++_operationGeneration;
    await _sessionSubscription?.cancel();
    await super.close();
  }
}
