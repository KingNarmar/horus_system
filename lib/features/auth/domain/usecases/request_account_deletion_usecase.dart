import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/account_deletion_status.dart';
import '../repositories/account_deletion_repository.dart';

final class RequestAccountDeletionUseCase
    implements UseCase<AccountDeletionStatus, NoParams> {
  final AccountDeletionRepository _repository;

  const RequestAccountDeletionUseCase(this._repository);

  @override
  Future<Result<AccountDeletionStatus>> call(NoParams params) {
    return _repository.requestDeletion();
  }
}
