import 'failure.dart';

class ValidationFailure extends Failure {
  const ValidationFailure({required super.code, super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.code, super.message});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.code, super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.code, super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.code, super.message});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.code, super.message});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.code, super.message});
}

class ConflictFailure extends Failure {
  const ConflictFailure({required super.code, super.message});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.code = 'unexpected_error', super.message});
}
