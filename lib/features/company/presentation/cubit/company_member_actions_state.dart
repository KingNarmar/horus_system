import '../../../../core/errors/failure.dart';

sealed class CompanyMemberActionsState {
  final String? companyId;

  const CompanyMemberActionsState({this.companyId});
}

class CompanyMemberActionsInitial extends CompanyMemberActionsState {
  const CompanyMemberActionsInitial();
}

class CompanyMemberActionInProgress extends CompanyMemberActionsState {
  const CompanyMemberActionInProgress({required super.companyId});
}

class CompanyMemberActionSucceeded extends CompanyMemberActionsState {
  const CompanyMemberActionSucceeded({required super.companyId});
}

class CompanyMemberActionFailed extends CompanyMemberActionsState {
  final Failure failure;

  const CompanyMemberActionFailed({
    required super.companyId,
    required this.failure,
  });
}
