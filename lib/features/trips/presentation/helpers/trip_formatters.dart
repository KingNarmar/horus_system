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
