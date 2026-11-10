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

/// The explicit creation route can show the form regardless of memberships.
class CompanyOnboardingReady extends CompanyOnboardingState {
  const CompanyOnboardingReady();
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

class CompanyOnboardingCreated extends CompanyOnboardingState {
  final Company company;

  const CompanyOnboardingCreated(this.company);
}

class CompanyOnboardingFailure extends CompanyOnboardingState {
  final Failure failure;

  const CompanyOnboardingFailure(this.failure);
}
