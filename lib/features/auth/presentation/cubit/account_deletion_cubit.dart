import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/account_deletion_status.dart';
import '../../domain/usecases/cancel_account_deletion_usecase.dart';
import '../../domain/usecases/get_account_deletion_status_usecase.dart';
import '../../domain/usecases/request_account_deletion_usecase.dart';
import 'account_deletion_state.dart';

final class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  final GetAccountDeletionStatusUseCase _getStatus;
  final RequestAccountDeletionUseCase _requestDeletion;
  final CancelAccountDeletionUseCase _cancelDeletion;

  AccountDeletionCubit({
    required GetAccountDeletionStatusUseCase getStatus,
    required RequestAccountDeletionUseCase requestDeletion,
    required CancelAccountDeletionUseCase cancelDeletion,
  }) : _getStatus = getStatus,
       _requestDeletion = requestDeletion,
       _cancelDeletion = cancelDeletion,
       super(const AccountDeletionInitial());

  Future<void> load() async {
    emit(const AccountDeletionLoading());
    _emit(await _getStatus(const NoParams()));
  }

  Future<void> requestDeletion() async {
    emit(const AccountDeletionLoading());
    _emit(await _requestDeletion(const NoParams()));
  }

  Future<void> cancelDeletion() async {
    emit(const AccountDeletionLoading());
    _emit(await _cancelDeletion(const NoParams()));
  }

  void _emit(Result<AccountDeletionStatus> result) {
    result.when(
      success: (status) => emit(AccountDeletionReady(status)),
      failure: (failure) => emit(AccountDeletionFailure(failure)),
    );
  }
}
