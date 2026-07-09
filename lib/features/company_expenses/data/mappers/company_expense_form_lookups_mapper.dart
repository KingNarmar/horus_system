import '../../domain/entities/company_expense_form_lookups.dart';
import '../../domain/entities/company_expense_link_option.dart';
import '../models/company_expense_form_lookups_model.dart';
import '../models/company_expense_link_option_model.dart';

extension CompanyExpenseFormLookupsModelMapper
    on CompanyExpenseFormLookupsModel {
  CompanyExpenseFormLookups toEntity() {
    return CompanyExpenseFormLookups(
      drivers: drivers.map((model) => model.toEntity()).toList(),
      tractorHeads: tractorHeads.map((model) => model.toEntity()).toList(),
      trailers: trailers.map((model) => model.toEntity()).toList(),
      trips: trips.map((model) => model.toEntity()).toList(),
    );
  }
}

extension CompanyExpenseLinkOptionModelMapper on CompanyExpenseLinkOptionModel {
  CompanyExpenseLinkOption toEntity() {
    return CompanyExpenseLinkOption(id: id, label: label);
  }
}
