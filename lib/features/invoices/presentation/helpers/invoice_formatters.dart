import 'package:intl/intl.dart';

import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice_trip_line.dart';

String formatInvoiceDate(DateTime? date, String localeName, String fallback) {
  if (date == null) return fallback;
  return DateFormat.yMMMd(localeName).format(date);
}

String formatInvoiceDateTime(DateTime date, String localeName) {
  return DateFormat.yMMMd(localeName).add_jm().format(date.toLocal());
}

String formatInvoiceInputDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatInvoiceMoney(
  Money money, {
  required int fractionDigits,
  required String localeName,
}) {
  final divisor = _powerOfTen(fractionDigits);
  final amount = money.minorUnits / divisor;
  final pattern = fractionDigits == 0
      ? '#,##0'
      : '#,##0.${List.filled(fractionDigits, '0').join()}';
  final formatted = NumberFormat(pattern, localeName).format(amount);
  return '${money.currency.value} $formatted';
}

String formatBillableTripReference(
  BillableTrip trip, {
  required String localeName,
  required String fallback,
}) {
  final parts = <String>[];
  final primaryReference = _firstNonBlank([
    trip.tripNumber,
    trip.loadingOrderNumber,
    trip.waybillNumber,
  ]);
  final customerName = _nonBlank(trip.customerName);
  final route = _routeLabel(trip.loadingLocation, trip.unloadingLocation);

  if (primaryReference != null) parts.add(primaryReference);
  if (customerName != null) parts.add(customerName);
  if (route != null) parts.add(route);
  if (trip.serviceDate != null) {
    parts.add(formatInvoiceDate(trip.serviceDate, localeName, fallback));
  }

  return parts.isEmpty ? fallback : parts.join(' — ');
}

String formatInvoiceLineReference(
  InvoiceTripLine line, {
  required String fallback,
}) {
  final parts = <String>[];
  final primaryReference = _firstNonBlank([
    line.tripNumber,
    line.loadingOrderNumber,
    line.waybillNumber,
  ]);
  final route = _routeLabel(line.loadingLocation, line.unloadingLocation);

  if (primaryReference != null) parts.add(primaryReference);
  if (route != null) parts.add(route);

  return parts.isEmpty ? fallback : parts.join(' — ');
}

String? _routeLabel(String? loadingLocation, String? unloadingLocation) {
  final loading = _nonBlank(loadingLocation);
  final unloading = _nonBlank(unloadingLocation);
  if (loading != null && unloading != null) return '$loading → $unloading';
  return loading ?? unloading;
}

String? _firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    final normalized = _nonBlank(value);
    if (normalized != null) return normalized;
  }
  return null;
}

String? _nonBlank(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}

int _powerOfTen(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index++) {
    result *= 10;
  }
  return result;
}
