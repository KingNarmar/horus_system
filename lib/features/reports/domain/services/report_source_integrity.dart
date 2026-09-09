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
    final sharedFailure = _validateSharedMetadata(
      companyId: metadata.companyId,
      businessTimezone: metadata.businessTimezone,
      fromDate: metadata.fromDate,
      toDate: metadata.toDate,
      expectedCompanyId: expectedCompanyId,
      expectedBusinessTimezone: expectedBusinessTimezone,
      expectedFromDate: expectedFromDate,
      expectedToDate: expectedToDate,
    );
    if (sharedFailure != null) return sharedFailure;

    if (metadata.baseCurrencyFractionDigits != expectedFractionDigits) {
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

  static Failure? validateOperationalMetadata({
    required OperationalReportSourceMetadata metadata,
    required String expectedCompanyId,
    required String expectedBusinessTimezone,
    required DateTime? expectedFromDate,
    required DateTime? expectedToDate,
  }) {
    return _validateSharedMetadata(
      companyId: metadata.companyId,
      businessTimezone: metadata.businessTimezone,
      fromDate: metadata.fromDate,
      toDate: metadata.toDate,
      expectedCompanyId: expectedCompanyId,
      expectedBusinessTimezone: expectedBusinessTimezone,
      expectedFromDate: expectedFromDate,
      expectedToDate: expectedToDate,
    );
  }

  static bool hasInvalidCounter(Iterable<int> counters) {
    return counters.any((value) => value < 0);
  }

  static Failure? _validateSharedMetadata({
    required String companyId,
    required String businessTimezone,
    required DateTime? fromDate,
    required DateTime? toDate,
    required String expectedCompanyId,
    required String expectedBusinessTimezone,
    required DateTime? expectedFromDate,
    required DateTime? expectedToDate,
  }) {
    if (companyId != expectedCompanyId ||
        businessTimezone != expectedBusinessTimezone ||
        !_sameDate(fromDate, expectedFromDate) ||
        !_sameDate(toDate, expectedToDate)) {
      return const ConflictFailure(
        code: ReportsFailureCodes.conflictSourceInvalid,
      );
    }

    return null;
  }

  static bool _sameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) return left == right;
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
