import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/current_company_context.dart';
import '../../domain/usecases/get_company_timezone_options_usecase.dart';
import '../../domain/usecases/update_company_business_timezone_usecase.dart';
import 'company_timezone_state.dart';

final class CompanyTimezoneCubit extends Cubit<CompanyTimezoneState> {
  final GetCompanyTimezoneOptionsUseCase _getOptionsUseCase;
  final UpdateCompanyBusinessTimezoneUseCase _updateTimezoneUseCase;

  CompanyTimezoneCubit({
    required GetCompanyTimezoneOptionsUseCase getOptionsUseCase,
    required UpdateCompanyBusinessTimezoneUseCase updateTimezoneUseCase,
  }) : _getOptionsUseCase = getOptionsUseCase,
       _updateTimezoneUseCase = updateTimezoneUseCase,
       super(const CompanyTimezoneInitial());

  Future<void> loadOptions() async {
    emit(const CompanyTimezoneLoading());
    final result = await _getOptionsUseCase(const NoParams());

    result.when(
      success: (options) => emit(CompanyTimezoneReady(options: options)),
      failure: (failure) => emit(CompanyTimezoneFailure(failure: failure)),
    );
  }

  Future<void> updateBusinessTimezone({
    required CurrentCompanyContext currentCompanyContext,
    required String businessTimezone,
  }) async {
    final options = state.options;
    emit(CompanyTimezoneSaving(options: options));

    final result = await _updateTimezoneUseCase(
      UpdateCompanyBusinessTimezoneParams(
        currentCompanyContext: currentCompanyContext,
        businessTimezone: businessTimezone,
      ),
    );

    result.when(
      success: (company) =>
          emit(CompanyTimezoneSaved(options: options, company: company)),
      failure: (failure) =>
          emit(CompanyTimezoneFailure(failure: failure, options: options)),
    );
  }
}
