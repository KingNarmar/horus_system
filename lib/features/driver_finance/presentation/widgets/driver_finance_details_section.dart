import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/money_formatter.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/driver_balance_activity.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import 'driver_balance_activity_list.dart';

class DriverFinanceDetailsSection extends StatelessWidget {
  final DriverBalanceActivity? activity;
  final List<DriverFinanceTripOption> tripOptions;
  final bool canManage;
  final bool isLoading;
  final bool isSaving;
  final Failure? failure;
  final Failure? realtimeRefreshFailure;
  final VoidCallback? onAddAdvance;
  final VoidCallback? onAddDriverCharge;
  final VoidCallback? onAddCashReturn;

  const DriverFinanceDetailsSection({
    required this.activity,
    required this.tripOptions,
    required this.canManage,
    required this.isLoading,
    required this.isSaving,
    required this.failure,
    this.realtimeRefreshFailure,
    this.onAddAdvance,
    this.onAddDriverCharge,
    this.onAddCashReturn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = activity?.canonicalBalance;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.driverBalanceActivityTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.driverBalancePlaceholderDescription),
            if (balance != null) ...[
              const SizedBox(height: AppSpacing.md),
              AdaptiveDetailRow(
                label: l10n.netDriverBalanceLabel,
                value: _balanceText(
                  context,
                  balance.netBalance.minorUnits,
                  balance.currencyFractionDigits,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AdaptiveDetailRow(
                label: l10n.driverBalanceActivityOpeningBalance,
                value: formatLocalizedMoney(
                  balance.openingBalance,
                  fractionDigits: balance.currencyFractionDigits,
                  localeName: localeName,
                ),
              ),
            ],
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
                    label: Text(l10n.addDriverChargeButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: isSaving ? null : onAddCashReturn,
                    icon: const Icon(AppIcons.cashReturn),
                    label: Text(l10n.driverMovementTypeCashReturn),
                  ),
                ],
              ),
            ],
            if (realtimeRefreshFailure != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.localizedErrorMessage(realtimeRefreshFailure!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (isLoading && activity == null)
              Text(l10n.driverBalanceActivityLoading)
            else if (failure != null)
              Text(l10n.localizedErrorMessage(failure!))
            else if (activity != null)
              DriverBalanceActivityList(
                activity: activity!,
                tripOptions: tripOptions,
              ),
          ],
        ),
      ),
    );
  }

  String _balanceText(
    BuildContext context,
    int minorUnits,
    int fractionDigits,
  ) {
    final l10n = context.l10n;
    if (minorUnits == 0) return l10n.driverBalanceSettled;
    final balance = activity!.canonicalBalance.netBalance;
    final unsigned = Money(
      minorUnits: balance.minorUnits.abs(),
      currency: balance.currency,
    );
    final formatted = formatLocalizedMoney(
      unsigned,
      fractionDigits: fractionDigits,
      localeName: Localizations.localeOf(context).toLanguageTag(),
    );
    return minorUnits < 0
        ? l10n.driverBalanceDriverOwesCompany(formatted)
        : l10n.driverBalanceCompanyOwesDriver(formatted);
  }
}
