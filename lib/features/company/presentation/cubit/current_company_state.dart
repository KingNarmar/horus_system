import '../../../../core/errors/failure.dart';
import '../../domain/entities/current_company_context.dart';

sealed class CurrentCompanyState {
  const CurrentCompanyState();
}

class CurrentCompanyInitial extends CurrentCompanyState {
  const CurrentCompanyInitial();
}

class CurrentCompanyLoading extends CurrentCompanyState {
  const CurrentCompanyLoading();
}

class CurrentCompanyEmpty extends CurrentCompanyState {
  const CurrentCompanyEmpty();
}

class CurrentCompanyLoaded extends CurrentCompanyState {
  final CurrentCompanyContext context;

  const CurrentCompanyLoaded(this.context);
}

class CurrentCompanyFailure extends CurrentCompanyState {
  final Failure failure;

  const CurrentCompanyFailure(this.failure);
}
