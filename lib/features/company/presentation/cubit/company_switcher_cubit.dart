import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_switchable_company_contexts_usecase.dart';
import 'company_switcher_state.dart';

/// Owns only the available-membership list. Active tenant selection belongs
/// to CurrentCompanyCubit and its authoritative refresh use case.
final class CompanySwitcherCubit extends Cubit<CompanySwitcherState> {
  final GetSwitchableCompanyContextsUseCase _getCompanies;
  int _requestGeneration = 0;

  CompanySwitcherCubit({
    required GetSwitchableCompanyContextsUseCase getCompanies,
  }) : _getCompanies = getCompanies,
       super(const CompanySwitcherInitial());

  Future<void> load() async {
    final request = ++_requestGeneration;
    emit(const CompanySwitcherLoading());

    final result = await _getCompanies(const NoParams());
    if (isClosed || request != _requestGeneration) return;

    result.when(
      success: (companies) => emit(CompanySwitcherLoaded(companies)),
      failure: (failure) => emit(CompanySwitcherFailure(failure)),
    );
  }

  @override
  Future<void> close() async {
    ++_requestGeneration;
    await super.close();
  }
}
