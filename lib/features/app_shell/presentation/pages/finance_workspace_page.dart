import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company_expenses/di/company_expenses_dependencies.dart';
import '../../../company_expenses/presentation/cubit/company_expenses_cubit.dart';
import '../../../company_expenses/presentation/pages/company_expenses_page.dart';
import '../../../customer_statements/di/customer_statements_dependencies.dart';
import '../../../customer_statements/presentation/cubit/customer_statements_cubit.dart';
import '../../../customer_statements/presentation/pages/customer_statements_page.dart';
import '../../../driver_finance/di/driver_finance_dependencies.dart';
import '../../../driver_finance/presentation/cubit/driver_finance_cubit.dart';
import '../../../driver_finance/presentation/pages/driver_finance_page.dart';
import '../../../driver_settlements/di/driver_settlements_dependencies.dart';
import '../../../driver_settlements/presentation/cubit/driver_settlements_cubit.dart';
import '../../../driver_settlements/presentation/pages/driver_settlements_page.dart';
import '../../../invoices/di/invoices_dependencies.dart';
import '../../../invoices/presentation/cubit/invoices_cubit.dart';
import '../../../invoices/presentation/pages/invoices_page.dart';
import '../../../payments/di/payments_dependencies.dart';
import '../../../payments/presentation/cubit/payments_cubit.dart';
import '../../../payments/presentation/pages/payments_page.dart';
import '../models/finance_workspace_section.dart';

final class FinanceWorkspacePage extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final FinanceWorkspaceSection selectedSection;
  final ValueChanged<FinanceWorkspaceSection> onSectionSelected;

  const FinanceWorkspacePage({
    required this.currentCompanyContext,
    required this.selectedSection,
    required this.onSectionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sections = financeWorkspaceSectionsForRole(
      currentCompanyContext.role,
    );
    if (sections.isEmpty) return const SizedBox.shrink();

    final resolvedSection = sections.contains(selectedSection)
        ? selectedSection
        : sections.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveLayout(
          mobile: _CompactFinanceNavigation(
            sections: sections,
            selectedSection: resolvedSection,
            onSelected: onSectionSelected,
          ),
          tablet: _CompactFinanceNavigation(
            sections: sections,
            selectedSection: resolvedSection,
            onSelected: onSectionSelected,
          ),
          desktop: _DesktopFinanceNavigation(
            sections: sections,
            selectedSection: resolvedSection,
            onSelected: onSectionSelected,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _FinanceSectionContent(
          currentCompanyContext: currentCompanyContext,
          section: resolvedSection,
        ),
      ],
    );
  }
}

final class _DesktopFinanceNavigation extends StatelessWidget {
  final List<FinanceWorkspaceSection> sections;
  final FinanceWorkspaceSection selectedSection;
  final ValueChanged<FinanceWorkspaceSection> onSelected;

  const _DesktopFinanceNavigation({
    required this.sections,
    required this.selectedSection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final section in sections)
          ChoiceChip(
            avatar: Icon(section.icon),
            label: Text(section.label(context)),
            selected: section == selectedSection,
            onSelected: (_) => onSelected(section),
          ),
      ],
    );
  }
}

final class _CompactFinanceNavigation extends StatelessWidget {
  final List<FinanceWorkspaceSection> sections;
  final FinanceWorkspaceSection selectedSection;
  final ValueChanged<FinanceWorkspaceSection> onSelected;

  const _CompactFinanceNavigation({
    required this.sections,
    required this.selectedSection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FinanceWorkspaceSection>(
          value: selectedSection,
          isExpanded: true,
          items: sections
              .map(
                (section) => DropdownMenuItem(
                  value: section,
                  child: Row(
                    children: [
                      Icon(section.icon),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          section.label(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (section) {
            if (section != null) onSelected(section);
          },
        ),
      ),
    );
  }
}

final class _FinanceSectionContent extends StatelessWidget {
  final CurrentCompanyContext currentCompanyContext;
  final FinanceWorkspaceSection section;

  const _FinanceSectionContent({
    required this.currentCompanyContext,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      FinanceWorkspaceSection.driverFinance => BlocProvider<DriverFinanceCubit>(
        create: (_) => DriverFinanceDependencies.createCubit(),
        child: DriverFinancePage(currentCompanyContext: currentCompanyContext),
      ),
      FinanceWorkspaceSection.driverSettlements =>
        BlocProvider<DriverSettlementsCubit>(
          create: (_) => DriverSettlementsDependencies.createCubit(),
          child: DriverSettlementsPage(
            currentCompanyContext: currentCompanyContext,
          ),
        ),
      FinanceWorkspaceSection.companyExpenses =>
        BlocProvider<CompanyExpensesCubit>(
          create: (_) => CompanyExpensesDependencies.createCubit(),
          child: CompanyExpensesPage(
            currentCompanyContext: currentCompanyContext,
          ),
        ),
      FinanceWorkspaceSection.invoices => BlocProvider<InvoicesCubit>(
        create: (_) => InvoicesDependencies.createInvoicesCubit(),
        child: InvoicesPage(currentCompanyContext: currentCompanyContext),
      ),
      FinanceWorkspaceSection.payments => BlocProvider<PaymentsCubit>(
        create: (_) => PaymentsDependencies.createPaymentsCubit(),
        child: PaymentsPage(currentCompanyContext: currentCompanyContext),
      ),
      FinanceWorkspaceSection.customerStatements =>
        BlocProvider<CustomerStatementsCubit>(
          create: (_) => CustomerStatementsDependencies.createCubit(),
          child: CustomerStatementsPage(
            currentCompanyContext: currentCompanyContext,
          ),
        ),
    };
  }
}
