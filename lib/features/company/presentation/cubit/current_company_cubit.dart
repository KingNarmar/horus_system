import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/clear_current_company_context_usecase.dart';
import '../../domain/usecases/load_current_company_context_usecase.dart';
import '../../domain/usecases/select_current_company_usecase.dart';
import 'current_company_state.dart';

class CurrentCompanyCubit extends Cubit<CurrentCompanyState> {
  final LoadCurrentCompanyContextUseCase _loadCurrentCompanyContextUseCase;
  final SelectCurrentCompanyUseCase _selectCurrentCompanyUseCase;
  final ClearCurrentCompanyContextUseCase _clearCurrentCompanyContextUseCase;

  CurrentCompanyCubit({
    required LoadCurrentCompanyContextUseCase loadCurrentCompanyContextUseCase,
    required SelectCurrentCompanyUseCase selectCurrentCompanyUseCase,
    required ClearCurrentCompanyContextUseCase clearCurrentCompanyContextUseCase,
  })  : _loadCurrentCompanyContextUseCase = loadCurrentCompanyContextUseCase,
        _selectCurrentCompanyUseCase = selectCurrentCompanyUseCase,
        _clearCurrentCompanyContextUseCase = clearCurrentCompanyContextUseCase,
        super(const CurrentCompanyInitial());

  Future<void> loadCurrentCompanyContext() async {
    emit(const CurrentCompanyLoading());

    final result = await _loadCurrentCompanyContextUseCase(const NoParams());

    result.when(
      success: (context) {
        if (context == null) {
          emit(const CurrentCompanyEmpty());
          return;
        }

        emit(CurrentCompanyLoaded(context));
      },
      failure: (failure) => emit(CurrentCompanyFailure(failure)),
    );
  }

  Future<void> selectCompany(String companyId) async {
    emit(const CurrentCompanyLoading());

    final result = await _selectCurrentCompanyUseCase(
      SelectCurrentCompanyParams(companyId: companyId),
    );

    result.when(
      success: (context) => emit(CurrentCompanyLoaded(context)),
      failure: (failure) => emit(CurrentCompanyFailure(failure)),
    );
  }

  Future<void> clearCurrentCompanyContext() async {
    final result = await _clearCurrentCompanyContextUseCase(const NoParams());

    result.when(
      success: (_) => emit(const CurrentCompanyEmpty()),
      failure: (failure) => emit(CurrentCompanyFailure(failure)),
    );
  }
}
