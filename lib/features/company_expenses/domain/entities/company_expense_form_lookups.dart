import 'company_expense_link_option.dart';

class CompanyExpenseFormLookups {
  final List<CompanyExpenseLinkOption> drivers;
  final List<CompanyExpenseLinkOption> tractorHeads;
  final List<CompanyExpenseLinkOption> trailers;
  final List<CompanyExpenseLinkOption> trips;

  const CompanyExpenseFormLookups({
    this.drivers = const [],
    this.tractorHeads = const [],
    this.trailers = const [],
    this.trips = const [],
  });
}
