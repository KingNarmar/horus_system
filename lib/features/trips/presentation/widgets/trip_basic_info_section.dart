import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripBasicInfoSection extends StatelessWidget {
  final TripEntity trip;

  const TripBasicInfoSection({required this.trip, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TripDetailsCard(
      children: [
        TripDetailRow(
          label: l10n.tripLoadingOrderHeader,
          value: TripFormatters.optionalText(
            trip.loadingOrderNumber,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripWaybillHeader,
          value: TripFormatters.optionalText(
            trip.waybillNumber,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripCustomerHeader,
          value: TripFormatters.optionalText(
            trip.customerName,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripRouteHeader,
          value: TripFormatters.optionalText(
            trip.routeName,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripDriverHeader,
          value: TripFormatters.optionalText(
            trip.driverName,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripVehicleHeader,
          value: TripFormatters.vehicleText(trip, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripQuantityHeader,
          value: TripFormatters.quantityTons(
            trip.quantityTons,
            l10n.tripEmptyValue,
            l10n.tripTonsSuffix,
          ),
        ),
        TripDetailRow(
          label: l10n.tripFreightPriceHeader,
          value: TripFormatters.money(trip.freightPrice, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripTotalExpensesLabel,
          value: TripFormatters.money(trip.totalExpenses, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripNetProfitHeader,
          value: TripFormatters.money(trip.netProfit, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripStatusHeader,
          value: l10n.tripStatusLabel(trip.status),
        ),
        TripDetailRow(
          label: l10n.tripScheduledLoadingAtLabel,
          value: formatTripDateTime(
            trip.scheduledLoadingAt,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripScheduledDeliveryAtLabel,
          value: formatTripDateTime(
            trip.scheduledDeliveryAt,
            l10n.tripEmptyValue,
          ),
        ),
        TripDetailRow(
          label: l10n.tripActualLoadingAtLabel,
          value: formatTripDateTime(trip.actualLoadingAt, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripActualDeliveryAtLabel,
          value: formatTripDateTime(trip.actualDeliveryAt, l10n.tripEmptyValue),
        ),
        TripDetailRow(
          label: l10n.tripNotesLabel,
          value: TripFormatters.optionalText(trip.notes, l10n.tripEmptyValue),
        ),
      ],
    );
  }
}
