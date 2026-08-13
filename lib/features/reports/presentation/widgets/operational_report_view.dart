import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../trips/presentation/localization/trips_localizations_x.dart';
import '../../domain/entities/operational_trip_report.dart';
import '../helpers/reports_formatters.dart';
import '../localization/reports_localizations.dart';

final class OperationalReportView extends StatelessWidget {
  final OperationalTripReport report;

  const OperationalReportView({required this.report, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    if (report.groups.isEmpty) return Text(strings.noRows);

    if (report.dimension == OperationalReportDimension.day) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: report.groups
            .map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _DailyTripsGroupCard(group: group),
              ),
            )
            .toList(growable: false),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= AppSizes.dataTableBreakpoint
            ? _GroupedTripsTable(report: report)
            : _GroupedTripsCards(report: report);
      },
    );
  }
}

final class _DailyTripsGroupCard extends StatelessWidget {
  final OperationalTripReportGroup group;

  const _DailyTripsGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final date = group.date;
    final label = date == null
        ? strings.unassigned
        : formatReportDate(date, localeName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(strings.groupTrips(group.tripCount)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth >= AppSizes.dataTableBreakpoint
                    ? _DailyTripsTable(rows: group.rows)
                    : _DailyTripsCards(rows: group.rows);
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _GroupedTripsTable extends StatelessWidget {
  final OperationalTripReport report;

  const _GroupedTripsTable({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(_dimensionLabel(strings, report.dimension))),
            DataColumn(label: Text(strings.tripsCount), numeric: true),
          ],
          rows: report.groups
              .map(
                (group) => DataRow(
                  cells: [
                    DataCell(Text(group.entityLabel ?? strings.unassigned)),
                    DataCell(Text(group.tripCount.toString())),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

final class _GroupedTripsCards extends StatelessWidget {
  final OperationalTripReport report;

  const _GroupedTripsCards({required this.report});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final label = _dimensionLabel(strings, report.dimension);
    return Column(
      children: report.groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.entityLabel ?? strings.unassigned,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(label, group.entityLabel ?? strings.unassigned),
                      _Line(strings.tripsCount, group.tripCount.toString()),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

final class _DailyTripsTable extends StatelessWidget {
  final List<OperationalTripReportRow> rows;

  const _DailyTripsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(strings.trip)),
          DataColumn(label: Text(strings.date)),
          DataColumn(label: Text(strings.customer)),
          DataColumn(label: Text(strings.driver)),
          DataColumn(label: Text(strings.tractorHead)),
          DataColumn(label: Text(strings.trailer)),
          DataColumn(label: Text(strings.route)),
          DataColumn(label: Text(strings.status)),
        ],
        rows: rows
            .map(
              (row) => DataRow(
                cells: [
                  DataCell(
                    Text(reportDisplayValue(row.tripNumber, row.tripId)),
                  ),
                  DataCell(
                    Text(formatReportDate(row.operationalDate, localeName)),
                  ),
                  DataCell(Text(row.customerName)),
                  DataCell(Text(row.driverName ?? strings.unassigned)),
                  DataCell(
                    Text(row.tractorHeadPlateNumber ?? strings.unassigned),
                  ),
                  DataCell(Text(row.trailerPlateNumber ?? strings.unassigned)),
                  DataCell(
                    Text('${row.loadingLocation} → ${row.unloadingLocation}'),
                  ),
                  DataCell(Text(context.l10n.tripStatusLabel(row.status))),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

final class _DailyTripsCards extends StatelessWidget {
  final List<OperationalTripReportRow> rows;

  const _DailyTripsCards({required this.rows});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportDisplayValue(row.tripNumber, row.tripId),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _Line(
                        strings.date,
                        formatReportDate(row.operationalDate, localeName),
                      ),
                      _Line(strings.customer, row.customerName),
                      _Line(
                        strings.driver,
                        row.driverName ?? strings.unassigned,
                      ),
                      _Line(
                        strings.tractorHead,
                        row.tractorHeadPlateNumber ?? strings.unassigned,
                      ),
                      _Line(
                        strings.trailer,
                        row.trailerPlateNumber ?? strings.unassigned,
                      ),
                      _Line(
                        strings.route,
                        '${row.loadingLocation} → ${row.unloadingLocation}',
                      ),
                      _Line(
                        strings.status,
                        context.l10n.tripStatusLabel(row.status),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

String _dimensionLabel(
  ReportsLocalizations strings,
  OperationalReportDimension dimension,
) {
  return switch (dimension) {
    OperationalReportDimension.day => strings.date,
    OperationalReportDimension.customer => strings.customer,
    OperationalReportDimension.driver => strings.driver,
    OperationalReportDimension.tractorHead => strings.tractorHead,
    OperationalReportDimension.trailer => strings.trailer,
  };
}

final class _Line extends StatelessWidget {
  final String label;
  final String value;

  const _Line(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text('$label: $value'),
    );
  }
}
