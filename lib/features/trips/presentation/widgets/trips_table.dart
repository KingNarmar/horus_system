import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_actions.dart';
import 'trip_status_chip.dart';

class TripsTable extends StatelessWidget {
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
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth =
            constraints.maxWidth < 1040 ? 1040.0 : constraints.maxWidth;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableMinWidth),
              child: DataTable(
                columnSpacing: AppSpacing.xl,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 96,
                headingRowHeight: 48,
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
                  DataColumn(label: Text(l10n.tripActionsHeader)),
                ],
                rows: [
                  for (final trip in trips)
                    DataRow(
                      cells: [
                        DataCell(
                          _PrimaryTripCell(
                            title: trip.displayName,
                            subtitle: TripFormatters.optionalText(
                              trip.waybillNumber,
                              l10n.tripEmptyValue,
                            ),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            TripFormatters.optionalText(
                              trip.customerName,
                              l10n.tripEmptyValue,
                            ),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            TripFormatters.optionalText(
                              trip.routeName,
                              l10n.tripEmptyValue,
                            ),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            TripFormatters.optionalText(
                              trip.driverName,
                              l10n.tripEmptyValue,
                            ),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            TripFormatters.vehicleText(
                              trip,
                              l10n.tripEmptyValue,
                            ),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            TripFormatters.quantityTons(
                              trip.quantityTons,
                              l10n.tripEmptyValue,
                              l10n.tripTonsSuffix,
                            ),
                          ),
                        ),
                        if (canViewTripFinancials)
                          DataCell(
                            _TextCell(
                              TripFormatters.money(
                                trip.freightPrice,
                                l10n.tripEmptyValue,
                              ),
                            ),
                          ),
                        DataCell(TripStatusChip(trip: trip)),
                        DataCell(
                          SizedBox(
                            width: 292,
                            child: TripActions(
                              trip: trip,
                              canManageTrips: canManageTrips,
                              canUpdateTripStatus: canUpdateTripStatus,
                              isChanging: isStatusChanging(trip.id),
                              onViewDetails: onViewDetails,
                              onEdit: onEdit,
                              onUpdateStatus: onUpdateStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryTripCell extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PrimaryTripCell({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
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
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;

  const _TextCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
