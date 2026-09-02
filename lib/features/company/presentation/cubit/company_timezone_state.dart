import '../../../../core/errors/failure.dart';
import '../../domain/entities/company.dart';
import '../../domain/value_objects/company_timezone.dart';

sealed class CompanyTimezoneState {
  final List<CompanyTimezone> options;

  const CompanyTimezoneState({this.options = const []});
}

final class CompanyTimezoneInitial extends CompanyTimezoneState {
  const CompanyTimezoneInitial();
}

final class CompanyTimezoneLoading extends CompanyTimezoneState {
  const CompanyTimezoneLoading();
}

final class CompanyTimezoneReady extends CompanyTimezoneState {
  const CompanyTimezoneReady({required super.options});
}

final class CompanyTimezoneSaving extends CompanyTimezoneState {
  const CompanyTimezoneSaving({required super.options});
}

final class CompanyTimezoneSaved extends CompanyTimezoneState {
  final Company company;

  const CompanyTimezoneSaved({
    required super.options,
    required this.company,
  });
}

final class CompanyTimezoneFailure extends CompanyTimezoneState {
  final Failure failure;

  const CompanyTimezoneFailure({
    required this.failure,
    super.options,
  });
}
