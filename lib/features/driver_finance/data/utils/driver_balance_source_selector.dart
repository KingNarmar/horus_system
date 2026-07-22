import '../../../../core/data/constants/db_common_fields.dart';

class DriverBalanceSourceSelector {
  const DriverBalanceSourceSelector();

  List<Map<String, dynamic>> select({
    required Iterable<Map<String, dynamic>> rows,
    required String effectiveDateField,
    required DateTime beforeExclusive,
    DateTime? checkpointPeriodEnd,
    DateTime? checkpointSnapshotCreatedAt,
  }) {
    if ((checkpointPeriodEnd == null) !=
        (checkpointSnapshotCreatedAt == null)) {
      throw const FormatException(
        'Checkpoint period end and snapshot time must be provided together.',
      );
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row[DbCommonFields.id] as String?;
      if (id == null || id.isEmpty) {
        throw const FormatException('Financial source id is required.');
      }

      final effectiveDate = _requiredDate(row[effectiveDateField]);
      if (!effectiveDate.isBefore(beforeExclusive)) continue;

      final isEligible =
          checkpointPeriodEnd == null ||
          effectiveDate.isAfter(checkpointPeriodEnd) ||
          _requiredDate(
            row[DbCommonFields.createdAt],
          ).isAfter(checkpointSnapshotCreatedAt!);
      if (isEligible) byId[id] = row;
    }

    final selected = byId.values.toList();
    selected.sort((left, right) {
      final effectiveComparison = _requiredDate(
        left[effectiveDateField],
      ).compareTo(_requiredDate(right[effectiveDateField]));
      if (effectiveComparison != 0) return effectiveComparison;

      final createdComparison = _requiredDate(
        left[DbCommonFields.createdAt],
      ).compareTo(_requiredDate(right[DbCommonFields.createdAt]));
      if (createdComparison != 0) return createdComparison;

      return (left[DbCommonFields.id] as String).compareTo(
        right[DbCommonFields.id] as String,
      );
    });
    return selected;
  }

  DateTime _requiredDate(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid date value: $value');
    return parsed;
  }
}
