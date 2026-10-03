import '../../../../core/errors/failure.dart';

sealed class PasswordRecoveryState {
  const PasswordRecoveryState();
}

final class PasswordRecoveryInitial extends PasswordRecoveryState {
  const PasswordRecoveryInitial();
}

final class PasswordRecoverySubmitting extends PasswordRecoveryState {
  const PasswordRecoverySubmitting();
}

final class PasswordRecoverySubmitted extends PasswordRecoveryState {
  const PasswordRecoverySubmitted();
}

final class PasswordRecoveryFailure extends PasswordRecoveryState {
  final Failure failure;

  const PasswordRecoveryFailure(this.failure);
}
