import '../entities/operational_trip_report.dart';

final class OperationalReportAggregator {
  const OperationalReportAggregator();

  List<OperationalTripReportGroup> group({
    required List<OperationalTripReportRow> rows,
    required OperationalReportDimension dimension,
  }) {
    return switch (dimension) {
      OperationalReportDimension.day => _groupByDay(rows),
      OperationalReportDimension.customer => _groupByEntity(
        rows,
        idOf: (row) => row.customerId,
        labelOf: (row) => row.customerName,
      ),
      OperationalReportDimension.driver => _groupByEntity(
        rows,
        idOf: (row) => row.driverId,
        labelOf: (row) => row.driverName,
      ),
      OperationalReportDimension.tractorHead => _groupByEntity(
        rows,
        idOf: (row) => row.tractorHeadId,
        labelOf: (row) => row.tractorHeadPlateNumber,
      ),
      OperationalReportDimension.trailer => _groupByEntity(
        rows,
        idOf: (row) => row.trailerId,
        labelOf: (row) => row.trailerPlateNumber,
      ),
    };
  }

  List<OperationalTripReportGroup> _groupByDay(
    List<OperationalTripReportRow> rows,
  ) {
    final grouped = <DateTime, List<OperationalTripReportRow>>{};
    for (final row in rows) {
      final date = DateTime(
        row.operationalDate.year,
        row.operationalDate.month,
        row.operationalDate.day,
      );
      (grouped[date] ??= <OperationalTripReportRow>[]).add(row);
    }

    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return List.unmodifiable(
      dates.map(
        (date) => OperationalTripReportGroup(
          date: date,
          entityId: null,
          entityLabel: null,
          rows: grouped[date]!,
        ),
      ),
    );
  }

  List<OperationalTripReportGroup> _groupByEntity(
    List<OperationalTripReportRow> rows, {
    required String? Function(OperationalTripReportRow row) idOf,
    required String? Function(OperationalTripReportRow row) labelOf,
  }) {
    final assigned = <String, _MutableEntityGroup>{};
    final unassigned = <OperationalTripReportRow>[];

    for (final row in rows) {
      final id = idOf(row)?.trim();
      final label = labelOf(row)?.trim();
      if (id == null || id.isEmpty || label == null || label.isEmpty) {
        unassigned.add(row);
        continue;
      }
      final group = assigned.putIfAbsent(
        id,
        () => _MutableEntityGroup(id: id, label: label),
      );
      group.rows.add(row);
    }

    final groups = assigned.values.toList()
      ..sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );

    final result = <OperationalTripReportGroup>[
      ...groups.map(
        (group) => OperationalTripReportGroup(
          date: null,
          entityId: group.id,
          entityLabel: group.label,
          rows: group.rows,
        ),
      ),
    ];
    if (unassigned.isNotEmpty) {
      result.add(
        OperationalTripReportGroup(
          date: null,
          entityId: null,
          entityLabel: null,
          rows: unassigned,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}

final class _MutableEntityGroup {
  final String id;
  final String label;
  final List<OperationalTripReportRow> rows = [];

  _MutableEntityGroup({required this.id, required this.label});
}
