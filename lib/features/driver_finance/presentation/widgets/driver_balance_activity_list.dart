import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/money_formatter.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../domain/entities/driver_balance_activity.dart';
import '../../domain/entities/driver_balance_activity_entry.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../localization/driver_finance_localizations_x.dart';

/// Progressive statement rendering keeps long histories usable on mobile.
final class DriverBalanceActivityList extends StatefulWidget {
  static const int pageSize = 40;

  final DriverBalanceActivity activity;
  final List<DriverFinanceTripOption> tripOptions;

  const DriverBalanceActivityList({
    required this.activity,
    required this.tripOptions,
    super.key,
  });

  @override
  State<DriverBalanceActivityList> createState() =>
      _DriverBalanceActivityListState();
}

final class _DriverBalanceActivityListState
    extends State<DriverBalanceActivityList> {
  int _visibleCount = DriverBalanceActivityList.pageSize;

  @override
  void didUpdateWidget(covariant DriverBalanceActivityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.canonicalBalance.driverId !=
            widget.activity.canonicalBalance.driverId ||
        oldWidget.activity.canonicalBalance.companyId !=
            widget.activity.canonicalBalance.companyId) {
      _visibleCount = DriverBalanceActivityList.pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final activity = widget.activity;
    final moneyBalance = activity.canonicalBalance;
    final checkpoint = moneyBalance.checkpoint;
    final entries = activity.entries.reversed.toList(growable: false);
    final count = _visibleCount < entries.length
        ? _visibleCount
        : entries.length;
    final tripLabels = {
      for (final trip in widget.tripOptions) trip.id: trip.label,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (checkpoint != null) ...[
          Text(
            l10n.driverBalanceActivityCheckpoint(
              _formattedDate(checkpoint.periodEnd, localeName),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          l10n.driverBalanceActivityVoidedHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (entries.isEmpty)
          Text(l10n.driverBalanceActivityEmpty)
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            itemBuilder: (context, index) => _ActivityItem(
              key: ValueKey(entries[index].stableId),
              entry: entries[index],
              tripLabel: tripLabels[entries[index].tripId],
              fractionDigits: moneyBalance.currencyFractionDigits,
              localeName: localeName,
            ),
          ),
          if (count < entries.length)
            TextButton(
              onPressed: () => setState(
                () => _visibleCount += DriverBalanceActivityList.pageSize,
              ),
              child: Text(l10n.driverBalanceActivityShowMore),
            ),
        ],
      ],
    );
  }
}

final class _ActivityItem extends StatelessWidget {
  final DriverBalanceActivityEntry entry;
  final String? tripLabel;
  final int fractionDigits;
  final String localeName;

  const _ActivityItem({
    required this.entry,
    required this.tripLabel,
    required this.fractionDigits,
    required this.localeName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final impact = entry.balanceImpact;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.driverActivityKindLabel(entry.kind),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              AdaptiveDetailRow(
                label: l10n.driverBalanceActivityImpact,
                value: formatLocalizedMoney(
                  impact,
                  fractionDigits: fractionDigits,
                  localeName: localeName,
                ),
              ),
              Text(_formattedDate(entry.businessDate, localeName)),
              if (entry.tripId != null)
                Text(
                  '${l10n.driverMovementTripLine}: ${tripLabel ?? entry.tripId}',
                ),
              if (entry.description != null)
                Text(
                  '${l10n.driverBalanceActivityDescription}: ${entry.description}',
                ),
              if (entry.notes != null) Text(entry.notes!),
              Text(l10n.driverActivitySourceLabel(entry.source)),
              SelectableText(
                '${l10n.driverBalanceActivitySourceReference}: ${entry.sourceId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formattedDate(BusinessDate businessDate, String localeName) {
  return DateFormat.yMMMd(
    localeName,
  ).format(BusinessDateDateTimeAdapter.toDateTime(businessDate));
}
