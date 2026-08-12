import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/money_formatter.dart';
import '../../domain/entities/customer_statement.dart';
import '../../domain/entities/customer_statement_line.dart';
import '../../domain/entities/customer_statement_movement_type.dart';
import '../helpers/customer_statement_formatters.dart';
import '../localization/customer_statements_localizations.dart';

final class CustomerStatementMovements extends StatelessWidget {
  final CustomerStatement statement;

  const CustomerStatementMovements({required this.statement, super.key});

  @override
  Widget build(BuildContext context) {
    if (statement.lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: Text(context.customerStatementsL10n.noMovements)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
          return _MovementsTable(statement: statement);
        }
        return _MovementCards(statement: statement);
      },
    );
  }
}

final class _MovementsTable extends StatelessWidget {
  final CustomerStatement statement;

  const _MovementsTable({required this.statement});

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(strings.date)),
          DataColumn(label: Text(strings.type)),
          DataColumn(label: Text(strings.reference)),
          DataColumn(label: Text(strings.amount)),
          DataColumn(label: Text(strings.balance)),
        ],
        rows: statement.lines
            .map(
              (line) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      formatCustomerStatementDate(
                        line.movement.businessDate,
                        localeName,
                      ),
                    ),
                  ),
                  DataCell(Text(_typeLabel(context, line))),
                  DataCell(
                    Text(
                      line.movement.reference ?? strings.unavailableValue,
                    ),
                  ),
                  DataCell(Text(_money(context, line.signedAmount))),
                  DataCell(Text(_money(context, line.runningBalance))),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String _money(BuildContext context, Money money) {
    return formatLocalizedMoney(
      money,
      fractionDigits: statement.fractionDigits,
      localeName: Localizations.localeOf(context).toLanguageTag(),
    );
  }
}

final class _MovementCards extends StatelessWidget {
  final CustomerStatement statement;

  const _MovementCards({required this.statement});

  @override
  Widget build(BuildContext context) {
    final strings = context.customerStatementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Column(
      children: statement.lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _typeLabel(context, line),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        label: strings.date,
                        value: formatCustomerStatementDate(
                          line.movement.businessDate,
                          localeName,
                        ),
                      ),
                      _DetailRow(
                        label: strings.reference,
                        value:
                            line.movement.reference ?? strings.unavailableValue,
                      ),
                      _DetailRow(
                        label: strings.amount,
                        value: formatLocalizedMoney(
                          line.signedAmount,
                          fractionDigits: statement.fractionDigits,
                          localeName: localeName,
                        ),
                      ),
                      _DetailRow(
                        label: strings.balance,
                        value: formatLocalizedMoney(
                          line.runningBalance,
                          fractionDigits: statement.fractionDigits,
                          localeName: localeName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

String _typeLabel(BuildContext context, CustomerStatementLine line) {
  final strings = context.customerStatementsL10n;
  return switch (line.movement.type) {
    CustomerStatementMovementType.invoice => strings.invoice,
    CustomerStatementMovementType.payment => strings.payment,
  };
}

final class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}
