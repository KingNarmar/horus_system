import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../domain/entities/trip_entity.dart';

abstract final class TripFormatters {
  static String optionalText(String? value, String emptyValue) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return emptyValue;
    return text;
  }

  static String number(double? value, String emptyValue) {
    if (value == null) return emptyValue;

    final text = value.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  static String money(double? value, String emptyValue) {
    if (value == null) return emptyValue;
    return number(value, emptyValue);
  }

  static String moneyMinorUnits(
    int minorUnits,
    int fractionDigits,
    String emptyValue,
  ) {
    if (fractionDigits < 0) return emptyValue;

    final isNegative = minorUnits < 0;
    final digits = minorUnits.abs().toString().padLeft(fractionDigits + 1, '0');
    if (fractionDigits == 0) return '${isNegative ? '-' : ''}$digits';

    final whole = digits.substring(0, digits.length - fractionDigits);
    var fraction = digits.substring(digits.length - fractionDigits);
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    final sign = isNegative ? '-' : '';
    return fraction.isEmpty ? '$sign$whole' : '$sign$whole.$fraction';
  }

  static String businessDate(BusinessDate? value, String emptyValue) {
    if (value == null) return emptyValue;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String businessLocalDateTime(
    BusinessLocalDateTime? value,
    String emptyValue,
  ) {
    if (value == null) return emptyValue;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  static String quantityTons(
    double? value,
    String emptyValue,
    String tonsSuffix,
  ) {
    if (value == null) return emptyValue;
    return '${number(value, emptyValue)} $tonsSuffix';
  }

  static String vehicleText(TripEntity trip, String emptyValue) {
    final tractor = trip.tractorHeadPlateNumber?.trim();
    final trailer = trip.trailerPlateNumber?.trim();

    final hasTractor = tractor != null && tractor.isNotEmpty;
    final hasTrailer = trailer != null && trailer.isNotEmpty;

    if (!hasTractor && !hasTrailer) return emptyValue;
    if (hasTractor && hasTrailer) return '$tractor / $trailer';
    return hasTractor ? tractor : trailer!;
  }
}
