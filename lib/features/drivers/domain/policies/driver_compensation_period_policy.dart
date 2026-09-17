import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/driver_compensation_revision.dart';
import '../failures/driver_compensation_failure_codes.dart';

final class DriverCompensationPeriodPolicy {
  const DriverCompensationPeriodPolicy();

  bool isValidPeriod({
    required BusinessDate effectiveFrom,
    BusinessDate? effectiveTo,
  }) {
    return effectiveTo == null || !effectiveTo.isBefore(effectiveFrom);
  }

  bool periodsOverlap({
    required BusinessDate firstFrom,
    BusinessDate? firstTo,
    required BusinessDate secondFrom,
    BusinessDate? secondTo,
  }) {
    if (firstTo != null && firstTo.isBefore(secondFrom)) return false;
    if (secondTo != null && secondTo.isBefore(firstFrom)) return false;
    return true;
  }

  bool overlapsAny({
    required List<DriverCompensationRevision> revisions,
    required BusinessDate effectiveFrom,
    BusinessDate? effectiveTo,
  }) {
    return revisions.any(
      (revision) => periodsOverlap(
        firstFrom: revision.effectiveFrom,
        firstTo: revision.effectiveTo,
        secondFrom: effectiveFrom,
        secondTo: effectiveTo,
      ),
    );
  }

  Result<DriverCompensationRevision> resolveForDate({
    required List<DriverCompensationRevision> revisions,
    required BusinessDate targetDate,
  }) {
    final matches = revisions.where((revision) {
      final startsOnOrBefore = !revision.effectiveFrom.isAfter(targetDate);
      final endsOnOrAfter =
          revision.effectiveTo == null ||
          !revision.effectiveTo!.isBefore(targetDate);
      return startsOnOrBefore && endsOnOrAfter;
    }).toList();

    if (matches.isEmpty) {
      return const FailureResult<DriverCompensationRevision>(
        NotFoundFailure(code: DriverCompensationFailureCodes.notFoundForDate),
      );
    }

    if (matches.length > 1) {
      return const FailureResult<DriverCompensationRevision>(
        ConflictFailure(code: DriverCompensationFailureCodes.conflictOverlap),
      );
    }

    return Success(matches.single);
  }

  Result<DriverCompensationRevision> resolveForPeriod({
    required List<DriverCompensationRevision> revisions,
    required BusinessDate periodStart,
    required BusinessDate periodEnd,
  }) {
    final matches = revisions.where((revision) {
      final startsOnOrBefore = !revision.effectiveFrom.isAfter(periodStart);
      final endsOnOrAfter =
          revision.effectiveTo == null ||
          !revision.effectiveTo!.isBefore(periodEnd);
      return startsOnOrBefore && endsOnOrAfter;
    }).toList();

    if (matches.isEmpty) {
      return const FailureResult<DriverCompensationRevision>(
        NotFoundFailure(
          code: DriverCompensationFailureCodes.notFoundForPeriod,
        ),
      );
    }

    if (matches.length > 1) {
      return const FailureResult<DriverCompensationRevision>(
        ConflictFailure(code: DriverCompensationFailureCodes.conflictOverlap),
      );
    }

    return Success(matches.single);
  }
}
