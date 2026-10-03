import '../../../../core/utils/result.dart';

abstract interface class PasswordRecoveryRepository {
  Future<Result<void>> requestPasswordRecovery({required String email});
}
