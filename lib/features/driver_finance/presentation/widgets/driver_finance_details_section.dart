import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../localization/driver_finance_localizations_x.dart';

class DriverFinanceDetailsSection extends StatelessWidget {
  final List<DriverFinancialMovement> movements;
  final DriverBalance? balance;
  final List<DriverFinanceTripOption> tripOptions;
  final bool canManage;
  final bool isLoading;
  final bool isSaving;
  final Failure? failure;
  final VoidCallback? onAddAdvance;
  final VoidCallback? onAddDriverCharge;
  final VoidCallback? onAddCashReturn;

  const DriverFinanceDetailsSection({
    required this.movements,
    required this.balance,
    required this.tripOptions,
    required this.canManage,
    required this.isLoading,
    required this.isSaving,
    required this.failure,
    this.onAddAdvance,
    this.onAddDriverCharge,
    this.onAddCashReturn,
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              value: _money(balance?.totalDriverCharges ?? 0),
            ),
            _DetailRow(
              label: l10n.driverMovementTypeCashReturn,
              value: _money(balance?.totalCashReturns ?? 0),
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
                    onPressed: isSaving ? null : onAddDriverCharge,
                    icon: const Icon(AppIcons.expenses),
                    label: Text(l10n.addDriverDeductionButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: isSaving ? null : onAddCashReturn,
                    icon: const Icon(AppIcons.cashReturn),
                    label: Text(l10n.driverMovementTypeCashReturn),
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
              ...movements.map(
                (movement) =>
                    _MovementItem(movement: movement, tripOptions: tripOptions),
              ),
          ],
        ),
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  final DriverFinancialMovement movement;
  final List<DriverFinanceTripOption> tripOptions;

  const _MovementItem({required this.movement, required this.tripOptions});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tripLabel = _tripLabel(movement.tripId, tripOptions);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.driverMovementTypeLabel(movement.type)} - ${_money(movement.amount)} - ${_dateOnly(movement.movementDate)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (tripLabel != null)
            Text('${l10n.driverMovementTripLine}: $tripLabel'),
          if (movement.notes != null && movement.notes!.trim().isNotEmpty)
            Text(movement.notes!.trim()),
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

String? _tripLabel(String? tripId, List<DriverFinanceTripOption> tripOptions) {
  final normalizedTripId = tripId?.trim();
  if (normalizedTripId == null || normalizedTripId.isEmpty) return null;

  for (final option in tripOptions) {
    if (option.id == normalizedTripId) return option.label;
  }

  return normalizedTripId;
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _money(double value) => value.toStringAsFixed(2);
