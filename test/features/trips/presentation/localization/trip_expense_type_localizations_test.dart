import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/trips/presentation/localization/trips_localizations_x.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();

  group('Trip expense type localization', () {
    const expectedEn = <String, String>{
      'admin_costs': 'Admin costs',
      'emergency_maintenance': 'Emergency maintenance',
      'fines': 'Fines',
      'fuel': 'Fuel',
      'licenses_and_renewals': 'Licenses and renewals',
      'loading': 'Loading',
      'office_expenses': 'Office expenses',
      'oils_and_fluids': 'Oils and fluids',
      'other': 'Other',
      'rent': 'Rent',
      'road_fees': 'Road fees',
      'spare_parts': 'Spare parts',
      'tires': 'Tires',
      'unloading': 'Unloading',
      'vehicle_maintenance': 'Vehicle maintenance',
      'weighbridge': 'Weighbridge',
    };

    const expectedAr = <String, String>{
      'admin_costs': 'المصروفات الإدارية',
      'emergency_maintenance': 'صيانة طارئة',
      'fines': 'غرامات',
      'fuel': 'وقود',
      'licenses_and_renewals': 'التراخيص والتجديدات',
      'loading': 'تحميل',
      'office_expenses': 'مصروفات المكتب',
      'oils_and_fluids': 'الزيوت والسوائل',
      'other': 'أخرى',
      'rent': 'الإيجار',
      'road_fees': 'رسوم طرق',
      'spare_parts': 'قطع الغيار',
      'tires': 'الإطارات',
      'unloading': 'تفريغ',
      'vehicle_maintenance': 'صيانة المركبات',
      'weighbridge': 'ميزان',
    };

    test('maps every canonical ledger-eligible type in English and Arabic', () {
      expect(expectedAr.keys.toSet(), expectedEn.keys.toSet());

      for (final entry in expectedEn.entries) {
        final type = ExpenseType(
          id: entry.key,
          companyId: 'company-id',
          name: 'Database ${entry.key}',
          code: entry.key,
          isActive: true,
        );

        expect(en.tripExpenseTypeDisplayLabel(type), entry.value);
        expect(ar.tripExpenseTypeDisplayLabel(type), expectedAr[entry.key]);
        expect(en.tripExpenseTypeName(entry.key), entry.value);
        expect(ar.tripExpenseTypeName(entry.key), expectedAr[entry.key]);
      }
    });

    test('preserves historical driver advance and unknown fallback labels', () {
      expect(en.tripExpenseTypeName('driver_advance'), 'Driver advance');
      expect(ar.tripExpenseTypeName('driver_advance'), 'عهدة سائق');

      const customType = ExpenseType(
        id: 'custom-id',
        companyId: 'company-id',
        name: 'Custom Fee',
        code: 'custom_fee',
        isActive: true,
      );

      expect(en.tripExpenseTypeDisplayLabel(customType), 'Custom Fee');
      expect(ar.tripExpenseTypeDisplayLabel(customType), 'Custom Fee');
      expect(en.tripExpenseTypeName('Custom Fee'), 'Custom Fee');
      expect(ar.tripExpenseTypeName('Custom Fee'), 'Custom Fee');
    });
  });
}
