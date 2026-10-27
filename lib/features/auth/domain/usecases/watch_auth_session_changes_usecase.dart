import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/auth_session_change.dart';
import '../repositories/auth_session_changes_repository.dart';

final class WatchAuthSessionChangesUseCase
    implements StreamUseCase<AuthSessionChange, NoParams> {
  final AuthSessionChangesRepository _repository;

  const WatchAuthSessionChangesUseCase(this._repository);

  @override
  Stream<Result<AuthSessionChange>> call(NoParams params) =>
      _repository.watchSessionChanges().map(Success.new);
}
