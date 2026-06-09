import '../../../../core/errors/failure.dart';
import '../../domain/entities/company_user.dart';

sealed class CompanyUsersState {
  const CompanyUsersState();
}

class CompanyUsersInitial extends CompanyUsersState {
  const CompanyUsersInitial();
}

class CompanyUsersLoading extends CompanyUsersState {
  const CompanyUsersLoading();
}

class CompanyUsersLoaded extends CompanyUsersState {
  final List<CompanyUser> users;

  const CompanyUsersLoaded(this.users);
}

class CompanyUsersFailure extends CompanyUsersState {
  final Failure failure;

  const CompanyUsersFailure(this.failure);
}
