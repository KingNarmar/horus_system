import '../../../../core/errors/failure.dart';
import '../../domain/entities/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailureState extends AuthState {
  final Failure failure;

  const AuthFailureState(this.failure);
}
