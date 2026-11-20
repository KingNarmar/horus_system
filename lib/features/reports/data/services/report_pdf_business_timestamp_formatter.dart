import '../../../../core/domain/services/business_time_zone_converter.dart';
import '../../../../core/utils/result.dart';
import 'report_pdf_date_formatter.dart';

/// Formats authoritative UTC instants using the company's own timezone.
/// Never relies on the device timezone or a hardcoded UTC offset.
final class ReportPdfBusinessTimestampFormatter {
  final BusinessTimeZoneConverter _converter;

  const ReportPdfBusinessTimestampFormatter(this._converter);

  Result<String> format({
    required DateTime utcInstant,
    required String businessTimezone,
    required String localeName,
  }) {
    final local = _converter.toBusinessLocalDateTime(
      instant: utcInstant,
      timeZoneId: businessTimezone,
    );
    return local.when(
      success: (value) => Success(
        ReportPdfDateFormatter.businessTimestamp(
          value,
          localeName,
          businessTimezone,
        ),
      ),
      failure: (failure) => FailureResult<String>(failure),
    );
  }
}
