import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/reports/presentation/helpers/reports_formatters.dart';

void main() {
  test('formats BusinessDate without timezone conversion', () {
    expect(
      formatReportDate(
        BusinessDate(year: 2026, month: 9, day: 7),
        'en',
      ),
      contains('Sep'),
    );
  });

  group('reportTripDisplayValue', () {
    test('prefers trip number over all other readable references', () {
      expect(
        reportTripDisplayValue(
          tripNumber: ' TR-100 ',
          loadingOrderNumber: 'LO-200',
          waybillNumber: 'WB-300',
          loadingLocation: 'Dubai',
          unloadingLocation: 'Abu Dhabi',
          emptyValue: 'Not available',
        ),
        'TR-100',
      );
    });

    test('falls back from loading order to waybill in priority order', () {
      expect(
        reportTripDisplayValue(
          tripNumber: null,
          loadingOrderNumber: ' LO-200 ',
          waybillNumber: 'WB-300',
          loadingLocation: 'Dubai',
          unloadingLocation: 'Abu Dhabi',
          emptyValue: 'Not available',
        ),
        'LO-200',
      );

      expect(
        reportTripDisplayValue(
          tripNumber: ' ',
          loadingOrderNumber: null,
          waybillNumber: ' WB-300 ',
          loadingLocation: 'Dubai',
          unloadingLocation: 'Abu Dhabi',
          emptyValue: 'Not available',
        ),
        'WB-300',
      );
    });

    test('uses route when no business reference exists', () {
      expect(
        reportTripDisplayValue(
          tripNumber: null,
          loadingOrderNumber: null,
          waybillNumber: null,
          loadingLocation: ' Dubai ',
          unloadingLocation: ' Abu Dhabi ',
          emptyValue: 'Not available',
        ),
        'Dubai → Abu Dhabi',
      );
    });

    test('uses localized empty value when no readable trip value exists', () {
      const internalTripId = '4ba8dc8f-fa8c-4099-ab7c-ffedef6d4d1b';
      final result = reportTripDisplayValue(
        tripNumber: null,
        loadingOrderNumber: ' ',
        waybillNumber: null,
        loadingLocation: ' ',
        unloadingLocation: '',
        emptyValue: 'Not available',
      );

      expect(result, 'Not available');
      expect(result, isNot(internalTripId));
    });
  });
}
