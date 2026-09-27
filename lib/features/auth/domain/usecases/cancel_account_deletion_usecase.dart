import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/account_deletion_status.dart';
import '../repositories/account_deletion_repository.dart';

final class CancelAccountDeletionUseCase
    implements UseCase<AccountDeletionStatus, NoParams> {
  final AccountDeletionRepository _repository;

  const CancelAccountDeletionUseCase(this._repository);

  @override
  Future<Result<AccountDeletionStatus>> call(NoParams params) {
    return _repository.cancelDeletion();
  }
}
