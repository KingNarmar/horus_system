import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../entities/report_source_metadata.dart';
import '../failures/reports_failure_codes.dart';

abstract final class ReportSourceIntegrity {
  static Failure? validateMetadata({
    required ReportSourceMetadata metadata,
    required String expectedCompanyId,
    required CurrencyCode expectedCurrency,
    required int expectedFractionDigits,
    required String expectedBusinessTimezone,
    required DateTime? expectedFromDate,
    required DateTime? expectedToDate,
  }) {
    if (metadata.companyId != expectedCompanyId ||
        metadata.baseCurrencyFractionDigits != expectedFractionDigits ||
        metadata.businessTimezone != expectedBusinessTimezone ||
        !_sameDate(metadata.fromDate, expectedFromDate) ||
        !_sameDate(metadata.toDate, expectedToDate)) {
      return const ConflictFailure(
        code: ReportsFailureCodes.conflictSourceInvalid,
      );
    }

    if (metadata.currency != expectedCurrency) {
      return const ConflictFailure(
        code: ReportsFailureCodes.conflictCurrencyMismatch,
      );
    }

    return null;
  }

  static bool hasInvalidCounter(Iterable<int> counters) {
    return counters.any((value) => value < 0);
  }

  static bool _sameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) return left == right;
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
