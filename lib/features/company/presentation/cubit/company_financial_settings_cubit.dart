import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/current_company_context.dart';
import '../../domain/usecases/update_company_financial_configuration_usecase.dart';
import 'company_financial_settings_state.dart';

final class CompanyFinancialSettingsCubit
    extends Cubit<CompanyFinancialSettingsState> {
  final UpdateCompanyFinancialConfigurationUseCase _updateUseCase;

  CompanyFinancialSettingsCubit({
    required UpdateCompanyFinancialConfigurationUseCase updateUseCase,
  }) : _updateUseCase = updateUseCase,
       super(const CompanyFinancialSettingsInitial());

  Future<void> update({
    required CurrentCompanyContext currentCompanyContext,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  }) async {
    emit(const CompanyFinancialSettingsSaving());

    final result = await _updateUseCase(
      UpdateCompanyFinancialConfigurationParams(
        currentCompanyContext: currentCompanyContext,
        baseCurrencyCode: baseCurrencyCode,
        baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      ),
    );

    result.when(
      success: (company) => emit(CompanyFinancialSettingsSaved(company)),
      failure: (failure) => emit(CompanyFinancialSettingsFailure(failure)),
    );
  }
}
