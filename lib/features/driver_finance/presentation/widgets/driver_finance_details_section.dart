import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../localization/driver_finance_localizations_x.dart';

class DriverFinanceDetailsSection extends StatelessWidget {
  final List<DriverFinancialMovement> movements;
  final DriverBalance? balance;
  final bool canManage;
  final bool isLoading;
  final bool isSaving;
  final Failure? failure;
  final VoidCallback? onAddAdvance;
  final VoidCallback? onAddDeduction;

  const DriverFinanceDetailsSection({
    required this.movements,
    required this.balance,
    required this.canManage,
    required this.isLoading,
    required this.isSaving,
    required this.failure,
    this.onAddAdvance,
    this.onAddDeduction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.driverFinanceTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.driverBalancePlaceholderDescription),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              label: l10n.totalAdvancesLabel,
              value: _money(balance?.totalAdvances ?? 0),
            ),
            _DetailRow(
              label: l10n.totalDeductionsLabel,
              value: _money(balance?.totalDeductions ?? 0),
            ),
            _DetailRow(
              label: l10n.netDriverBalanceLabel,
              value: _money(balance?.netBalance ?? 0),
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: isSaving ? null : onAddAdvance,
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addDriverAdvanceButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: isSaving ? null : onAddDeduction,
                    icon: const Icon(AppIcons.expenses),
                    label: Text(l10n.addDriverDeductionButton),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (isLoading)
              Text(l10n.loadingDriverFinancialMovements)
            else if (failure != null)
              Text(l10n.localizedErrorMessage(failure!))
            else if (movements.isEmpty)
              Text(l10n.noDriverFinancialMovements)
            else
              ...movements.map((movement) => _MovementItem(movement: movement)),
          ],
        ),
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  final DriverFinancialMovement movement;

  const _MovementItem({required this.movement});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tripId = movement.tripId?.trim();
    final notes = movement.notes?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.driverMovementTypeLabel(movement.type),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(
            label: l10n.driverMovementAmountLabel,
            value: _signedMoney(movement),
          ),
          _DetailRow(
            label: l10n.driverMovementDateLabel,
            value: _dateOnly(movement.movementDate),
          ),
          if (tripId != null && tripId.isNotEmpty)
            _DetailRow(label: l10n.driverMovementTripLine, value: tripId),
          if (notes != null && notes.isNotEmpty)
            _DetailRow(label: l10n.driverMovementNotesLabel, value: notes),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.detailsLabelWidth,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _money(double value) => value.toStringAsFixed(2);

String _signedMoney(DriverFinancialMovement movement) {
  final sign = movement.type.isAdvance ? '+' : '-';
  return '$sign${_money(movement.amount)}';
}
