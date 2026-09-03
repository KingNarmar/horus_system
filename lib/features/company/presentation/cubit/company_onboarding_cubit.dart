import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/create_company_usecase.dart';
import '../../domain/usecases/get_my_companies_usecase.dart';
import 'company_onboarding_state.dart';

class CompanyOnboardingCubit extends Cubit<CompanyOnboardingState> {
  final CreateCompanyUseCase _createCompanyUseCase;
  final GetMyCompaniesUseCase _getMyCompaniesUseCase;

  CompanyOnboardingCubit({
    required CreateCompanyUseCase createCompanyUseCase,
    required GetMyCompaniesUseCase getMyCompaniesUseCase,
  }) : _createCompanyUseCase = createCompanyUseCase,
       _getMyCompaniesUseCase = getMyCompaniesUseCase,
       super(const CompanyOnboardingInitial());

  Future<void> loadMyCompanies() async {
    emit(const CompanyOnboardingLoading());

    final result = await _getMyCompaniesUseCase(const NoParams());

    result.when(
      success: (companies) {
        if (companies.isEmpty) {
          emit(const CompanyOnboardingEmpty());
          return;
        }

        emit(
          CompanyOnboardingLoaded(
            companies: companies,
            activeCompany: companies.first,
          ),
        );
      },
      failure: (failure) => emit(CompanyOnboardingFailure(failure)),
    );
  }

  Future<void> createCompany({
    required String name,
    required String businessTimezone,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    emit(const CompanyOnboardingLoading());

    final result = await _createCompanyUseCase(
      CreateCompanyParams(
        name: name,
        businessTimezone: businessTimezone,
        businessType: businessType,
        phone: phone,
        email: email,
        country: country,
        city: city,
      ),
    );

    result.when(
      success: (company) => emit(
        CompanyOnboardingLoaded(companies: [company], activeCompany: company),
      ),
      failure: (failure) => emit(CompanyOnboardingFailure(failure)),
    );
  }
}
