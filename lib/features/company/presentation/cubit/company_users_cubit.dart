import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/current_company_context.dart';
import '../../domain/usecases/get_company_users_usecase.dart';
import 'company_users_state.dart';

class CompanyUsersCubit extends Cubit<CompanyUsersState> {
  final GetCompanyUsersUseCase _getCompanyUsersUseCase;
  int _loadGeneration = 0;

  CompanyUsersCubit({required GetCompanyUsersUseCase getCompanyUsersUseCase})
    : _getCompanyUsersUseCase = getCompanyUsersUseCase,
      super(const CompanyUsersInitial());

  Future<void> loadCompanyUsers({
    required CurrentCompanyContext currentCompanyContext,
  }) async {
    if (isClosed) return;
    final request = ++_loadGeneration;
    emit(const CompanyUsersLoading());

    final result = await _getCompanyUsersUseCase(
      GetCompanyUsersParams(currentCompanyContext: currentCompanyContext),
    );

    if (isClosed || request != _loadGeneration) return;

    result.when(
      success: (users) => emit(CompanyUsersLoaded(users)),
      failure: (failure) => emit(CompanyUsersFailure(failure)),
    );
  }

  @override
  Future<void> close() async {
    ++_loadGeneration;
    await super.close();
  }
}
