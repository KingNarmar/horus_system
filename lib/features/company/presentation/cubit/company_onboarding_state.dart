import '../../../../core/errors/failure.dart';
import '../../domain/entities/company.dart';

sealed class CompanyOnboardingState {
  const CompanyOnboardingState();
}

class CompanyOnboardingInitial extends CompanyOnboardingState {
  const CompanyOnboardingInitial();
}

class CompanyOnboardingLoading extends CompanyOnboardingState {
  const CompanyOnboardingLoading();
}

class CompanyOnboardingEmpty extends CompanyOnboardingState {
  const CompanyOnboardingEmpty();
}

class CompanyOnboardingLoaded extends CompanyOnboardingState {
  final List<Company> companies;
  final Company activeCompany;

  const CompanyOnboardingLoaded({
    required this.companies,
    required this.activeCompany,
  });
}

class CompanyOnboardingFailure extends CompanyOnboardingState {
  final Failure failure;

  const CompanyOnboardingFailure(this.failure);
}
