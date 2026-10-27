import '../../../../core/errors/failure.dart';
import '../../domain/entities/current_company_context.dart';

sealed class CompanySwitcherState {
  const CompanySwitcherState();
}

final class CompanySwitcherInitial extends CompanySwitcherState {
  const CompanySwitcherInitial();
}

final class CompanySwitcherLoading extends CompanySwitcherState {
  const CompanySwitcherLoading();
}

final class CompanySwitcherLoaded extends CompanySwitcherState {
  final List<CurrentCompanyContext> companies;

  const CompanySwitcherLoaded(this.companies);
}

final class CompanySwitcherFailure extends CompanySwitcherState {
  final Failure failure;

  const CompanySwitcherFailure(this.failure);
}
