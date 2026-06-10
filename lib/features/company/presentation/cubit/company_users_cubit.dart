import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/current_company_context.dart';
import '../../domain/usecases/get_company_users_usecase.dart';
import 'company_users_state.dart';

class CompanyUsersCubit extends Cubit<CompanyUsersState> {
  final GetCompanyUsersUseCase _getCompanyUsersUseCase;

  CompanyUsersCubit({required GetCompanyUsersUseCase getCompanyUsersUseCase})
    : _getCompanyUsersUseCase = getCompanyUsersUseCase,
      super(const CompanyUsersInitial());

  Future<void> loadCompanyUsers({
    required CurrentCompanyContext currentCompanyContext,
  }) async {
    emit(const CompanyUsersLoading());

    final result = await _getCompanyUsersUseCase(
      GetCompanyUsersParams(currentCompanyContext: currentCompanyContext),
    );

    result.when(
      success: (users) => emit(CompanyUsersLoaded(users)),
      failure: (failure) => emit(CompanyUsersFailure(failure)),
    );
  }
}
