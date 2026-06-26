import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripBasicInfoSection extends StatelessWidget {
  final TripEntity trip;
  final double? calculatedAmount;

  const TripBasicInfoSection({required this.trip, this.calculatedAmount, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TripDetailsCard(
      children: [
        _InfoLine(label: l10n.tripCustomerHeader, value: TripFormatters.optionalText(trip.customerName, l10n.tripEmptyValue)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripRouteHeader, value: TripFormatters.optionalText(trip.routeName, l10n.tripEmptyValue)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripFreightPriceHeader, value: TripFormatters.money(trip.freightPrice, l10n.tripEmptyValue)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripTotalExpensesLabel, value: TripFormatters.money(trip.totalExpenses, l10n.tripEmptyValue)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripNetProfitHeader, value: TripFormatters.money(calculatedAmount, l10n.tripEmptyValue)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripStatusHeader, value: l10n.tripStatusLabel(trip.status)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripScheduledLoadingAtLabel, value: formatTripDateTime(trip.scheduledLoadingAt, l10n.tripEmptyValue)),
        const SizedBox(height: AppSpacing.sm),
        _InfoLine(label: l10n.tripScheduledDeliveryAtLabel, value: formatTripDateTime(trip.scheduledDeliveryAt, l10n.tripEmptyValue)),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
