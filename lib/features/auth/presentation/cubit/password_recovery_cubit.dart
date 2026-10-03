import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/request_password_recovery_usecase.dart';
import 'password_recovery_state.dart';

final class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  final RequestPasswordRecoveryUseCase _requestPasswordRecovery;

  PasswordRecoveryCubit({
    required RequestPasswordRecoveryUseCase requestPasswordRecovery,
  }) : _requestPasswordRecovery = requestPasswordRecovery,
       super(const PasswordRecoveryInitial());

  Future<void> requestRecovery({required String email}) async {
    if (state is PasswordRecoverySubmitting) {
      return;
    }

    emit(const PasswordRecoverySubmitting());

    final result = await _requestPasswordRecovery(
      RequestPasswordRecoveryParams(email: email),
    );

    result.when(
      success: (_) => emit(const PasswordRecoverySubmitted()),
      failure: (failure) => emit(PasswordRecoveryFailure(failure)),
    );
  }
}
