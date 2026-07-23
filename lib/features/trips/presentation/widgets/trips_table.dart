import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_actions.dart';
import 'trip_status_chip.dart';

class TripsTable extends StatelessWidget {
  static const double _wideBreakpoint = 1120;

  final List<TripEntity> trips;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool Function(String id) isStatusChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onEdit;
  final ValueChanged<TripEntity> onUpdateStatus;

  const TripsTable({
    required this.trips,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isStatusChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onUpdateStatus,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TripsTableHeader(
                  isWide: isWide,
                  canViewTripFinancials: canViewTripFinancials,
                ),
                const Divider(height: 1),
                for (final trip in trips) ...[
                  _TripsTableRow(
                    trip: trip,
                    isWide: isWide,
                    canManageTrips: canManageTrips,
                    canUpdateTripStatus: canUpdateTripStatus,
                    canViewTripFinancials: canViewTripFinancials,
                    isChanging: isStatusChanging(trip.id),
                    onViewDetails: onViewDetails,
                    onEdit: onEdit,
                    onUpdateStatus: onUpdateStatus,
                  ),
                  if (trip != trips.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TripsTableHeader extends StatelessWidget {
  final bool isWide;
  final bool canViewTripFinancials;

  const _TripsTableHeader({
    required this.isWide,
    required this.canViewTripFinancials,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _HeaderCell(label: l10n.tripLoadingOrderHeader, flex: 18),
          if (isWide) ...[
            _HeaderCell(label: l10n.tripCustomerHeader, flex: 16),
            _HeaderCell(label: l10n.tripRouteHeader, flex: 16),
            _HeaderCell(label: l10n.tripDriverHeader, flex: 16),
            _HeaderCell(label: l10n.tripVehicleHeader, flex: 16),
          ] else ...[
            _HeaderCell(label: l10n.tripCustomerHeader, flex: 22),
            _HeaderCell(label: l10n.tripVehicleHeader, flex: 22),
          ],
          _HeaderCell(
            label: canViewTripFinancials
                ? '${l10n.tripQuantityHeader} / ${l10n.tripFreightPriceHeader}'
                : l10n.tripQuantityHeader,
            flex: 14,
          ),
          _HeaderCell(label: l10n.tripStatusHeader, flex: 12),
          _HeaderCell(label: l10n.tripActionsHeader, flex: 16, alignEnd: true),
        ],
      ),
    );
  }
}

class _TripsTableRow extends StatelessWidget {
  final TripEntity trip;
  final bool isWide;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool isChanging;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onEdit;
  final ValueChanged<TripEntity> onUpdateStatus;

  const _TripsTableRow({
    required this.trip,
    required this.isWide,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    required this.isChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PrimaryCell(
            title: trip.displayName,
            subtitle: TripFormatters.optionalText(
              trip.waybillNumber,
              l10n.tripEmptyValue,
            ),
            flex: 18,
          ),
          if (isWide) ...[
            _TextCell(
              text: TripFormatters.optionalText(
                trip.customerName,
                l10n.tripEmptyValue,
              ),
              flex: 16,
            ),
            _TextCell(
              text: TripFormatters.optionalText(
                trip.routeName,
                l10n.tripEmptyValue,
              ),
              flex: 16,
            ),
            _TextCell(
              text: TripFormatters.optionalText(
                trip.driverName,
                l10n.tripEmptyValue,
              ),
              flex: 16,
            ),
            _TextCell(
              text: TripFormatters.vehicleText(trip, l10n.tripEmptyValue),
              flex: 16,
            ),
          ] else ...[
            _StackedCell(
              firstLabel: l10n.tripCustomerHeader,
              firstValue: TripFormatters.optionalText(
                trip.customerName,
                l10n.tripEmptyValue,
              ),
              secondLabel: l10n.tripRouteHeader,
              secondValue: TripFormatters.optionalText(
                trip.routeName,
                l10n.tripEmptyValue,
              ),
              flex: 22,
            ),
            _StackedCell(
              firstLabel: l10n.tripDriverHeader,
              firstValue: TripFormatters.optionalText(
                trip.driverName,
                l10n.tripEmptyValue,
              ),
              secondLabel: l10n.tripVehicleHeader,
              secondValue: TripFormatters.vehicleText(
                trip,
                l10n.tripEmptyValue,
              ),
              flex: 22,
            ),
          ],
          _StackedCell(
            firstLabel: l10n.tripQuantityHeader,
            firstValue: TripFormatters.quantityTons(
              trip.quantityTons,
              l10n.tripEmptyValue,
              l10n.tripTonsSuffix,
            ),
            secondLabel: l10n.tripFreightPriceHeader,
            secondValue: canViewTripFinancials
                ? TripFormatters.money(trip.freightPrice, l10n.tripEmptyValue)
                : l10n.tripEmptyValue,
            showSecond: canViewTripFinancials,
            flex: 14,
          ),
          Expanded(flex: 12, child: TripStatusChip(trip: trip)),
          Expanded(
            flex: 16,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TripActions(
                trip: trip,
                canManageTrips: canManageTrips,
                canUpdateTripStatus: canUpdateTripStatus,
                isChanging: isChanging,
                showLabels: false,
                onViewDetails: onViewDetails,
                onEdit: onEdit,
                onUpdateStatus: onUpdateStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool alignEnd;

  const _HeaderCell({
    required this.label,
    required this.flex,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _PrimaryCell extends StatelessWidget {
  final String title;
  final String subtitle;
  final int flex;

  const _PrimaryCell({
    required this.title,
    required this.subtitle,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != l10n.tripEmptyValue) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  final int flex;

  const _TextCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _StackedCell extends StatelessWidget {
  final String firstLabel;
  final String firstValue;
  final String secondLabel;
  final String secondValue;
  final int flex;
  final bool showSecond;

  const _StackedCell({
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
    required this.flex,
    this.showSecond = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SmallLine(label: firstLabel, value: firstValue),
            if (showSecond) ...[
              const SizedBox(height: AppSpacing.xs),
              _SmallLine(label: secondLabel, value: secondValue),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallLine extends StatelessWidget {
  final String label;
  final String value;

  const _SmallLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextSpan(
            text: value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
