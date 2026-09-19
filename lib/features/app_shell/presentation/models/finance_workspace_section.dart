import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company_expenses/domain/policies/company_expenses_permission_policy.dart';
import '../../../customer_statements/domain/policies/customer_statements_permission_policy.dart';
import '../../../customer_statements/presentation/localization/customer_statements_localizations.dart';
import '../../../driver_finance/domain/policies/driver_finance_permission_policy.dart';
import '../../../driver_settlements/domain/policies/driver_settlements_permission_policy.dart';
import '../../../driver_settlements/presentation/localization/driver_settlements_localizations.dart';
import '../../../invoices/domain/policies/invoices_permission_policy.dart';
import '../../../invoices/presentation/localization/invoices_localizations.dart';
import '../../../payments/domain/policies/payments_permission_policy.dart';
import '../../../payments/presentation/localization/payments_localizations.dart';
import '../../../../core/localization/app_localizations_extension.dart';

enum FinanceWorkspaceSection {
  driverFinance,
  driverSettlements,
  companyExpenses,
  invoices,
  payments,
  customerStatements,
}

extension FinanceWorkspaceSectionX on FinanceWorkspaceSection {
  bool canView(CompanyRole role) {
    return switch (this) {
      FinanceWorkspaceSection.driverFinance =>
        DriverFinancePermissionPolicy.canViewDriverFinance(role),
      FinanceWorkspaceSection.driverSettlements =>
        DriverSettlementsPermissionPolicy.canViewDriverSettlements(role),
      FinanceWorkspaceSection.companyExpenses =>
        CompanyExpensesPermissionPolicy.canViewCompanyExpenses(role),
      FinanceWorkspaceSection.invoices =>
        InvoicesPermissionPolicy.canViewInvoices(role),
      FinanceWorkspaceSection.payments =>
        PaymentsPermissionPolicy.canViewPayments(role),
      FinanceWorkspaceSection.customerStatements =>
        CustomerStatementsPermissionPolicy.canViewStatements(role),
    };
  }

  IconData get icon {
    return switch (this) {
      FinanceWorkspaceSection.driverFinance => AppIcons.driverSettlements,
      FinanceWorkspaceSection.driverSettlements => AppIcons.driverSettlements,
      FinanceWorkspaceSection.companyExpenses => AppIcons.expenses,
      FinanceWorkspaceSection.invoices => AppIcons.invoices,
      FinanceWorkspaceSection.payments => AppIcons.payments,
      FinanceWorkspaceSection.customerStatements => AppIcons.customerStatements,
    };
  }

  String label(BuildContext context) {
    return switch (this) {
      FinanceWorkspaceSection.driverFinance => context.l10n.driverFinanceTitle,
      FinanceWorkspaceSection.driverSettlements =>
        context.driverSettlementsL10n.title,
      FinanceWorkspaceSection.companyExpenses =>
        context.l10n.companyExpensesTitle,
      FinanceWorkspaceSection.invoices => context.invoicesL10n.title,
      FinanceWorkspaceSection.payments => context.paymentsL10n.title,
      FinanceWorkspaceSection.customerStatements =>
        context.customerStatementsL10n.title,
    };
  }
}

List<FinanceWorkspaceSection> financeWorkspaceSectionsForRole(
  CompanyRole role,
) {
  return FinanceWorkspaceSection.values
      .where((section) => section.canView(role))
      .toList(growable: false);
}

FinanceWorkspaceSection? resolveFinanceWorkspaceSection({
  required CompanyRole role,
  FinanceWorkspaceSection? preferred,
}) {
  final available = financeWorkspaceSectionsForRole(role);
  if (available.isEmpty) return null;
  if (preferred != null && available.contains(preferred)) return preferred;
  return available.first;
}
