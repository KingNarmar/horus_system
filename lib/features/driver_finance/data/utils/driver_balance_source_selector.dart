import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';

class DriverBalanceSourceSelector {
  const DriverBalanceSourceSelector();

  List<Map<String, dynamic>> select({
    required Iterable<Map<String, dynamic>> rows,
    required String effectiveDateField,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointPeriodEnd,
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

      final effectiveDate = DbDate.decode(
        row[effectiveDateField],
        field: effectiveDateField,
      );
      if (!effectiveDate.isBefore(beforeExclusive)) continue;

      final isEligible =
          checkpointPeriodEnd == null ||
          effectiveDate.isAfter(checkpointPeriodEnd) ||
          DbTimestamp.decode(
            row[DbCommonFields.createdAt],
            field: DbCommonFields.createdAt,
          ).isAfter(checkpointSnapshotCreatedAt!);
      if (isEligible) byId[id] = row;
    }

    final selected = byId.values.toList();
    selected.sort((left, right) {
      final effectiveComparison =
          DbDate.decode(
            left[effectiveDateField],
            field: effectiveDateField,
          ).compareTo(
            DbDate.decode(right[effectiveDateField], field: effectiveDateField),
          );
      if (effectiveComparison != 0) return effectiveComparison;

      final createdComparison =
          DbTimestamp.decode(
            left[DbCommonFields.createdAt],
            field: DbCommonFields.createdAt,
          ).compareTo(
            DbTimestamp.decode(
              right[DbCommonFields.createdAt],
              field: DbCommonFields.createdAt,
            ),
          );
      if (createdComparison != 0) return createdComparison;

      return (left[DbCommonFields.id] as String).compareTo(
        right[DbCommonFields.id] as String,
      );
    });
    return selected;
  }
}
