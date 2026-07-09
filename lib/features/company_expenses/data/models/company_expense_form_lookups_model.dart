import 'company_expense_link_option_model.dart';

class CompanyExpenseFormLookupsModel {
  final List<CompanyExpenseLinkOptionModel> drivers;
  final List<CompanyExpenseLinkOptionModel> tractorHeads;
  final List<CompanyExpenseLinkOptionModel> trailers;
  final List<CompanyExpenseLinkOptionModel> trips;

  const CompanyExpenseFormLookupsModel({
    this.drivers = const [],
    this.tractorHeads = const [],
    this.trailers = const [],
    this.trips = const [],
  });
}
