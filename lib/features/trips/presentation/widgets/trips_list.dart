import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';

class TripsList extends StatelessWidget {
  final List<TripEntity> trips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool Function(String id) isStatusChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onUpdateStatus;

  const TripsList({
    required this.trips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isStatusChanging,
    required this.onViewDetails,
    required this.onUpdateStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _TripsTable(
            trips: trips,
            canUpdateTripStatus: canUpdateTripStatus,
            canViewTripFinancials: canViewTripFinancials,
            isStatusChanging: isStatusChanging,
            onViewDetails: onViewDetails,
            onUpdateStatus: onUpdateStatus,
          );
        }

        return _TripsCards(
          trips: trips,
          canUpdateTripStatus: canUpdateTripStatus,
          canViewTripFinancials: canViewTripFinancials,
          isStatusChanging: isStatusChanging,
          onViewDetails: onViewDetails,
          onUpdateStatus: onUpdateStatus,
        );
      },
    );
  }
}

class _TripsTable extends StatelessWidget {
  final List<TripEntity> trips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool Function(String id) isStatusChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onUpdateStatus;

  const _TripsTable({
    required this.trips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isStatusChanging,
    required this.onViewDetails,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.tripLoadingOrderHeader)),
            DataColumn(label: Text(l10n.tripCustomerHeader)),
            DataColumn(label: Text(l10n.tripRouteHeader)),
            DataColumn(label: Text(l10n.tripDriverHeader)),
            DataColumn(label: Text(l10n.tripVehicleHeader)),
            DataColumn(label: Text(l10n.tripQuantityHeader)),
            if (canViewTripFinancials)
              DataColumn(label: Text(l10n.tripFreightPriceHeader)),
            DataColumn(label: Text(l10n.tripStatusHeader)),
            const DataColumn(label: SizedBox(width: 92)),
          ],
          rows: trips.map((trip) {
            final isChanging = isStatusChanging(trip.id);

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    TripFormatters.optionalText(
                      trip.loadingOrderNumber,
                      l10n.tripEmptyValue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    TripFormatters.optionalText(
                      trip.customerName,
                      l10n.tripEmptyValue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    TripFormatters.optionalText(
                      trip.routeName,
                      l10n.tripEmptyValue,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    TripFormatters.optionalText(
                      trip.driverName,
                      l10n.tripEmptyValue,
                    ),
                  ),
                ),
                DataCell(
                  Text(TripFormatters.vehicleText(trip, l10n.tripEmptyValue)),
                ),
                DataCell(
                  Text(
                    TripFormatters.quantityTons(
                      trip.quantityTons,
                      l10n.tripEmptyValue,
                      l10n.tripTonsSuffix,
                    ),
                  ),
                ),
                if (canViewTripFinancials)
                  DataCell(
                    Text(
                      TripFormatters.money(
                        trip.freightPrice,
                        l10n.tripEmptyValue,
                      ),
                    ),
                  ),
                DataCell(_TripStatusChip(trip: trip)),
                DataCell(
                  SizedBox(
                    width: 92,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _TripActions(
                        trip: trip,
                        canUpdateTripStatus: canUpdateTripStatus,
                        isChanging: isChanging,
                        onViewDetails: onViewDetails,
                        onUpdateStatus: onUpdateStatus,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TripsCards extends StatelessWidget {
  final List<TripEntity> trips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool Function(String id) isStatusChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onUpdateStatus;

  const _TripsCards({
    required this.trips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isStatusChanging,
    required this.onViewDetails,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: trips.map((trip) {
        final isChanging = isStatusChanging(trip.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  trip.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoText(
                      label: l10n.tripCustomerHeader,
                      value: TripFormatters.optionalText(
                        trip.customerName,
                        l10n.tripEmptyValue,
                      ),
                    ),
                    _InfoText(
                      label: l10n.tripRouteHeader,
                      value: TripFormatters.optionalText(
                        trip.routeName,
                        l10n.tripEmptyValue,
                      ),
                    ),
                    _InfoText(
                      label: l10n.tripDriverHeader,
                      value: TripFormatters.optionalText(
                        trip.driverName,
                        l10n.tripEmptyValue,
                      ),
                    ),
                    _InfoText(
                      label: l10n.tripVehicleHeader,
                      value: TripFormatters.vehicleText(
                        trip,
                        l10n.tripEmptyValue,
                      ),
                    ),
                    _InfoText(
                      label: l10n.tripQuantityHeader,
                      value: TripFormatters.quantityTons(
                        trip.quantityTons,
                        l10n.tripEmptyValue,
                        l10n.tripTonsSuffix,
                      ),
                    ),
                    if (canViewTripFinancials)
                      _InfoText(
                        label: l10n.tripFreightPriceHeader,
                        value: TripFormatters.money(
                          trip.freightPrice,
                          l10n.tripEmptyValue,
                        ),
                      ),
                    _TripStatusChip(trip: trip),
                  ],
                ),
                if (trip.notes != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(trip.notes!),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _TripActions(
                    trip: trip,
                    canUpdateTripStatus: canUpdateTripStatus,
                    isChanging: isChanging,
                    onViewDetails: onViewDetails,
                    onUpdateStatus: onUpdateStatus,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String label;
  final String value;

  const _InfoText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value');
  }
}

class _TripStatusChip extends StatelessWidget {
  final TripEntity trip;

  const _TripStatusChip({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Chip(label: Text(l10n.tripStatusLabel(trip.status)));
  }
}

class _TripActions extends StatelessWidget {
  final TripEntity trip;
  final bool canUpdateTripStatus;
  final bool isChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onUpdateStatus;

  const _TripActions({
    required this.trip,
    required this.canUpdateTripStatus,
    required this.isChanging,
    required this.onViewDetails,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canChangeStatus =
        canUpdateTripStatus && !trip.status.isTerminal && !isChanging;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIconButton(
          tooltip: l10n.tripViewDetails,
          onPressed: () => onViewDetails(trip),
          icon: const Icon(AppIcons.view),
        ),
        if (canUpdateTripStatus)
          _ActionIconButton(
            tooltip: l10n.tripUpdateStatus,
            onPressed: canChangeStatus ? () => onUpdateStatus(trip) : null,
            icon: isChanging
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.edit),
          ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;

  const _ActionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}
