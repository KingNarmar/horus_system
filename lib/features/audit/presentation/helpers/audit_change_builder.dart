import '../../domain/entities/audit_log.dart';

class AuditChange {
  final String label;
  final String oldValue;
  final String newValue;

  const AuditChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });
}

class AuditChangeBuilder {
  static List<AuditChange> buildChanges({
    required AuditLog log,
    required List<String> visibleKeys,
    required String Function(String key) fieldLabelBuilder,
    required String Function(String key, Object? value) valueLabelBuilder,
    bool Function(String key, Object? oldValue, Object? newValue)?
    valuesEqualBuilder,
  }) {
    final oldValues = log.oldValues;
    final newValues = log.newValues;
    if (oldValues == null || newValues == null) return const [];

    final changes = <AuditChange>[];
    for (final key in visibleKeys) {
      final oldValue = oldValues[key];
      final newValue = newValues[key];
      final valuesEqual = valuesEqualBuilder ?? _valuesEqual;
      if (valuesEqual(key, oldValue, newValue)) continue;
      changes.add(
        AuditChange(
          label: fieldLabelBuilder(key),
          oldValue: valueLabelBuilder(key, oldValue),
          newValue: valueLabelBuilder(key, newValue),
        ),
      );
    }
    return changes;
  }

  static bool _valuesEqual(String _, Object? oldValue, Object? newValue) {
    return oldValue?.toString() == newValue?.toString();
  }
}
