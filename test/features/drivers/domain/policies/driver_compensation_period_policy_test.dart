import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/failures/driver_compensation_failure_codes.dart';
import 'package:horus_system/features/drivers/domain/policies/driver_compensation_period_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DriverCompensationPeriodPolicy', () {
    const policy = DriverCompensationPeriodPolicy();

    test('treats effective period boundaries as inclusive', () {
      final first = BusinessDate(year: 2026, month: 1, day: 1);
      final last = BusinessDate(year: 2026, month: 7, day: 31);

      expect(
        policy.periodsOverlap(
          firstFrom: first,
          firstTo: last,
          secondFrom: last,
          secondTo: null,
        ),
        isTrue,
      );
      expect(
        policy.periodsOverlap(
          firstFrom: first,
          firstTo: last,
          secondFrom: last.nextDay,
          secondTo: null,
        ),
        isFalse,
      );
    });

    test('allows intentional gaps between revisions', () {
      final revisions = [
        _revision(
          id: 'jan',
          from: BusinessDate(year: 2026, month: 1, day: 1),
          to: BusinessDate(year: 2026, month: 1, day: 31),
        ),
        _revision(
          id: 'mar',
          from: BusinessDate(year: 2026, month: 3, day: 1),
          to: null,
        ),
      ];

      final result = policy.resolveForDate(
        revisions: revisions,
        targetDate: BusinessDate(year: 2026, month: 2, day: 15),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.notFoundForDate,
      );
    });

    test('resolves the revision effective on the target business date', () {
      final revisions = [
        _revision(
          id: 'old',
          from: BusinessDate(year: 2026, month: 1, day: 1),
          to: BusinessDate(year: 2026, month: 7, day: 31),
        ),
        _revision(
          id: 'new',
          from: BusinessDate(year: 2026, month: 8, day: 1),
          to: null,
        ),
      ];

      final september = policy.resolveForDate(
        revisions: revisions,
        targetDate: BusinessDate(year: 2026, month: 9, day: 1),
      );
      final january = policy.resolveForDate(
        revisions: revisions,
        targetDate: BusinessDate(year: 2026, month: 1, day: 31),
      );

      expect(september.dataOrNull?.id, 'new');
      expect(january.dataOrNull?.id, 'old');
    });

    test('rejects ambiguous overlapping history during resolution', () {
      final revisions = [
        _revision(
          id: 'a',
          from: BusinessDate(year: 2026, month: 1, day: 1),
          to: null,
        ),
        _revision(
          id: 'b',
          from: BusinessDate(year: 2026, month: 8, day: 1),
          to: null,
        ),
      ];

      final result = policy.resolveForDate(
        revisions: revisions,
        targetDate: BusinessDate(year: 2026, month: 9, day: 1),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.conflictOverlap,
      );
    });

    test('resolves one revision that covers the complete settlement period', () {
      final revision = _revision(
        id: 'current',
        from: BusinessDate(year: 2026, month: 1, day: 1),
        to: BusinessDate(year: 2026, month: 12, day: 31),
      );

      final result = policy.resolveForPeriod(
        revisions: [revision],
        periodStart: BusinessDate(year: 2026, month: 9, day: 1),
        periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
      );

      expect(result.dataOrNull?.id, 'current');
    });

    test('fails when any part of the settlement period has no compensation', () {
      final result = policy.resolveForPeriod(
        revisions: [
          _revision(
            id: 'partial',
            from: BusinessDate(year: 2026, month: 9, day: 10),
            to: null,
          ),
        ],
        periodStart: BusinessDate(year: 2026, month: 9, day: 1),
        periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.notFoundForPeriod,
      );
    });

    test('fails when settlement period crosses compensation revisions', () {
      final result = policy.resolveForPeriod(
        revisions: [
          _revision(
            id: 'old',
            from: BusinessDate(year: 2026, month: 1, day: 1),
            to: BusinessDate(year: 2026, month: 9, day: 14),
          ),
          _revision(
            id: 'new',
            from: BusinessDate(year: 2026, month: 9, day: 15),
            to: null,
          ),
        ],
        periodStart: BusinessDate(year: 2026, month: 9, day: 1),
        periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.conflictPeriodSpansRevisions,
      );
    });
  });
}

DriverCompensationRevision _revision({
  required String id,
  required BusinessDate from,
  required BusinessDate? to,
}) {
  final currency = CurrencyCode.tryParse('AED')!;
  return DriverCompensationRevision(
    id: id,
    companyId: 'company-1',
    driverId: 'driver-1',
    amount: Money(minorUnits: 500000, currency: currency),
    currencyFractionDigits: 2,
    effectiveFrom: from,
    effectiveTo: to,
  );
}
