import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_finance/data/utils/driver_balance_source_selector.dart';
import 'package:test/test.dart';

void main() {
  const selector = DriverBalanceSourceSelector();

  group('DriverBalanceSourceSelector', () {
    test('keeps only sources not captured by the finalized checkpoint', () {
      final selected = selector.select(
        rows: [
          _row(
            id: 'captured',
            effectiveDate: '2026-08-20',
            createdAt: '2026-08-21T08:00:00Z',
          ),
          _row(
            id: 'effective-after-period',
            effectiveDate: '2026-09-01',
            createdAt: '2026-08-30T08:00:00Z',
          ),
          _row(
            id: 'late-backdated',
            effectiveDate: '2026-08-20',
            createdAt: '2026-09-02T08:00:00Z',
          ),
          _row(
            id: 'future',
            effectiveDate: '2026-10-01',
            createdAt: '2026-09-02T08:00:00Z',
          ),
        ],
        effectiveDateField: 'movement_date',
        beforeExclusive: BusinessDate(year: 2026, month: 10, day: 1),
        checkpointPeriodEnd: BusinessDate(year: 2026, month: 8, day: 31),
        checkpointSnapshotCreatedAt: DateTime.utc(2026, 9, 1, 8),
      );

      expect(selected.map((row) => row['id']), [
        'late-backdated',
        'effective-after-period',
      ]);
    });

    test('deduplicates query overlap and orders deterministically', () {
      final duplicate = _row(
        id: 'same-id',
        effectiveDate: '2026-09-02',
        createdAt: '2026-09-02T09:00:00Z',
      );

      final selected = selector.select(
        rows: [
          _row(
            id: 'later-id',
            effectiveDate: '2026-09-03',
            createdAt: '2026-09-03T09:00:00Z',
          ),
          duplicate,
          duplicate,
          _row(
            id: 'earlier-created',
            effectiveDate: '2026-09-02',
            createdAt: '2026-09-02T08:00:00Z',
          ),
        ],
        effectiveDateField: 'movement_date',
        beforeExclusive: BusinessDate(year: 2026, month: 10, day: 1),
      );

      expect(selected.map((row) => row['id']), [
        'earlier-created',
        'same-id',
        'later-id',
      ]);
    });

    test('keeps the upper business-date boundary exclusive', () {
      final selected = selector.select(
        rows: [
          _row(
            id: 'first',
            effectiveDate: '2026-01-01',
            createdAt: '2026-01-01T08:00:00Z',
          ),
          _row(
            id: 'boundary',
            effectiveDate: '2026-10-01',
            createdAt: '2026-09-30T08:00:00Z',
          ),
        ],
        effectiveDateField: 'movement_date',
        beforeExclusive: BusinessDate(year: 2026, month: 10, day: 1),
      );

      expect(selected.map((row) => row['id']), ['first']);
    });

    test('rejects non-date-only effective values', () {
      expect(
        () => selector.select(
          rows: [
            _row(
              id: 'invalid',
              effectiveDate: '2026-09-02T00:00:00Z',
              createdAt: '2026-09-02T08:00:00Z',
            ),
          ],
          effectiveDateField: 'movement_date',
          beforeExclusive: BusinessDate(year: 2026, month: 10, day: 1),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _row({
  required String id,
  required String effectiveDate,
  required String createdAt,
}) {
  return {'id': id, 'movement_date': effectiveDate, 'created_at': createdAt};
}
