import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripBasicInfoSection extends StatelessWidget {
  static const double _threeColumnsBreakpoint = 620;
  static const double _twoColumnsBreakpoint = 300;

  final TripEntity trip;
  final double? calculatedAmount;

  const TripBasicInfoSection({
    required this.trip,
    this.calculatedAmount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return TripDetailsCard(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnsForWidth(constraints.maxWidth);
            final spacing = AppSpacing.md * (columns - 1);
            final tileWidth = (constraints.maxWidth - spacing) / columns;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    child: _TripBasicInfoTile(item: item),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<_TripBasicInfoItem> _buildItems(BuildContext context) {
    final l10n = context.l10n;
    final items = <_TripBasicInfoItem>[];

    void addRequired(String label, String value) {
      items.add(_TripBasicInfoItem(label: label, value: value));
    }

    void addOptional(String label, String value) {
      if (value == l10n.tripEmptyValue) return;
      items.add(_TripBasicInfoItem(label: label, value: value));
    }

    addOptional(
      l10n.tripLoadingOrderHeader,
      TripFormatters.optionalText(trip.loadingOrderNumber, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripWaybillHeader,
      TripFormatters.optionalText(trip.waybillNumber, l10n.tripEmptyValue),
    );

    addRequired(
      l10n.tripCustomerHeader,
      TripFormatters.optionalText(trip.customerName, l10n.tripEmptyValue),
    );

    addRequired(
      l10n.tripRouteHeader,
      TripFormatters.optionalText(trip.routeName, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripDriverHeader,
      TripFormatters.optionalText(trip.driverName, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripVehicleHeader,
      TripFormatters.vehicleText(trip, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripQuantityHeader,
      TripFormatters.quantityTons(
        trip.quantityTons,
        l10n.tripEmptyValue,
        l10n.tripTonsSuffix,
      ),
    );

    addOptional(
      l10n.tripFreightPriceHeader,
      TripFormatters.money(trip.freightPrice, l10n.tripEmptyValue),
    );

    addRequired(
      l10n.tripTotalExpensesLabel,
      TripFormatters.money(trip.totalExpenses, l10n.tripEmptyValue),
    );

    addRequired(
      l10n.tripNetProfitHeader,
      TripFormatters.money(calculatedAmount, l10n.tripEmptyValue),
    );

    addRequired(l10n.tripStatusHeader, l10n.tripStatusLabel(trip.status));

    addOptional(
      l10n.tripScheduledLoadingAtLabel,
      formatTripDateTime(trip.scheduledLoadingAt, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripScheduledDeliveryAtLabel,
      formatTripDateTime(trip.scheduledDeliveryAt, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripActualLoadingAtLabel,
      formatTripDateTime(trip.actualLoadingAt, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripActualDeliveryAtLabel,
      formatTripDateTime(trip.actualDeliveryAt, l10n.tripEmptyValue),
    );

    addOptional(
      l10n.tripNotesLabel,
      TripFormatters.optionalText(trip.notes, l10n.tripEmptyValue),
    );

    return items;
  }

  int _columnsForWidth(double width) {
    if (width >= _threeColumnsBreakpoint) return 3;
    if (width >= _twoColumnsBreakpoint) return 2;
    return 1;
  }
}

class _TripBasicInfoItem {
  final String label;
  final String value;

  const _TripBasicInfoItem({required this.label, required this.value});
}

class _TripBasicInfoTile extends StatelessWidget {
  final _TripBasicInfoItem item;

  const _TripBasicInfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final ambientDirection = Directionality.of(context);
    final textAlign = ambientDirection == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
