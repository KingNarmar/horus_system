import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status_filter.dart';
import 'package:horus_system/features/trips/presentation/localization/trips_localizations_x.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();

  group('Trips localization', () {
    test('provides representative static labels in English and Arabic', () {
      expect(en.tripsTitle, 'Trips');
      expect(ar.tripsTitle, 'الرحلات');

      expect(en.tripDetailsHeaderTitle, 'Trip details');
      expect(ar.tripDetailsHeaderTitle, 'تفاصيل الرحلة');

      expect(en.tripTotalExpensesLabel, 'Total expenses');
      expect(ar.tripTotalExpensesLabel, 'إجمالي المصروفات');

      expect(en.tripStatusHeader, 'Status');
      expect(ar.tripStatusHeader, 'الحالة');

      expect(en.tripActionsHeader, 'Actions');
      expect(ar.tripActionsHeader, 'الإجراءات');

      expect(en.tripNotesLabel, 'Notes');
      expect(ar.tripNotesLabel, 'ملاحظات');

      expect(en.tripSaveButton, 'Save');
      expect(ar.tripSaveButton, 'حفظ');

      expect(en.tripCancelButton, 'Cancel');
      expect(ar.tripCancelButton, 'إلغاء');

      expect(en.tripRetryButton, 'Retry');
      expect(ar.tripRetryButton, 'إعادة المحاولة');

      expect(en.tripUnknownUser, 'Unknown user');
      expect(ar.tripUnknownUser, 'مستخدم غير معروف');
    });

    test('maps every TripStatus in English and Arabic', () {
      final expectedEn = <TripStatus, String>{
        TripStatus.created: 'Created',
        TripStatus.assigned: 'Assigned',
        TripStatus.loaded: 'Loaded',
        TripStatus.onRoad: 'On road',
        TripStatus.arrived: 'Arrived',
        TripStatus.delivered: 'Delivered',
        TripStatus.documentsReceived: 'Documents received',
        TripStatus.invoiced: 'Invoiced',
        TripStatus.paid: 'Paid',
        TripStatus.cancelled: 'Cancelled',
      };

      final expectedAr = <TripStatus, String>{
        TripStatus.created: 'جديدة',
        TripStatus.assigned: 'مخصصة',
        TripStatus.loaded: 'تم التحميل',
        TripStatus.onRoad: 'على الطريق',
        TripStatus.arrived: 'وصلت',
        TripStatus.delivered: 'تم التسليم',
        TripStatus.documentsReceived: 'تم استلام المستندات',
        TripStatus.invoiced: 'تمت الفوترة',
        TripStatus.paid: 'مدفوعة',
        TripStatus.cancelled: 'ملغاة',
      };

      for (final entry in expectedEn.entries) {
        expect(en.tripStatusLabel(entry.key), entry.value);
      }

      for (final entry in expectedAr.entries) {
        expect(ar.tripStatusLabel(entry.key), entry.value);
      }
    });

    test('maps every TripStatusFilter in English and Arabic', () {
      final expectedEn = <TripStatusFilter, String>{
        TripStatusFilter.all: 'All',
        TripStatusFilter.open: 'Open',
        TripStatusFilter.created: 'Created',
        TripStatusFilter.assigned: 'Assigned',
        TripStatusFilter.loaded: 'Loaded',
        TripStatusFilter.onRoad: 'On road',
        TripStatusFilter.arrived: 'Arrived',
        TripStatusFilter.delivered: 'Delivered',
        TripStatusFilter.documentsReceived: 'Documents received',
        TripStatusFilter.invoiced: 'Invoiced',
        TripStatusFilter.paid: 'Paid',
        TripStatusFilter.cancelled: 'Cancelled',
      };

      final expectedAr = <TripStatusFilter, String>{
        TripStatusFilter.all: 'الكل',
        TripStatusFilter.open: 'المفتوحة',
        TripStatusFilter.created: 'جديدة',
        TripStatusFilter.assigned: 'مخصصة',
        TripStatusFilter.loaded: 'تم التحميل',
        TripStatusFilter.onRoad: 'على الطريق',
        TripStatusFilter.arrived: 'وصلت',
        TripStatusFilter.delivered: 'تم التسليم',
        TripStatusFilter.documentsReceived: 'تم استلام المستندات',
        TripStatusFilter.invoiced: 'تمت الفوترة',
        TripStatusFilter.paid: 'مدفوعة',
        TripStatusFilter.cancelled: 'ملغاة',
      };

      for (final entry in expectedEn.entries) {
        expect(en.tripStatusFilterLabel(entry.key), entry.value);
      }

      for (final entry in expectedAr.entries) {
        expect(ar.tripStatusFilterLabel(entry.key), entry.value);
      }
    });

    test('maps every TripExpensePaidBy in English and Arabic', () {
      final expectedEn = <TripExpensePaidBy, String>{
        TripExpensePaidBy.company: 'Company',
        TripExpensePaidBy.driverAdvance: 'Driver advance',
        TripExpensePaidBy.driverCash: 'Driver cash',
        TripExpensePaidBy.customer: 'Customer',
        TripExpensePaidBy.other: 'Other',
      };

      final expectedAr = <TripExpensePaidBy, String>{
        TripExpensePaidBy.company: 'الشركة',
        TripExpensePaidBy.driverAdvance: 'عهدة السائق',
        TripExpensePaidBy.driverCash: 'دفع السائق',
        TripExpensePaidBy.customer: 'العميل',
        TripExpensePaidBy.other: 'أخرى',
      };

      for (final entry in expectedEn.entries) {
        expect(en.tripExpensePaidByValueLabel(entry.key), entry.value);
      }

      for (final entry in expectedAr.entries) {
        expect(ar.tripExpensePaidByValueLabel(entry.key), entry.value);
      }
    });

    test('maps expense type names and preserves unknown values', () {
      final expectedEn = <String, String>{
        'fuel': 'Fuel',
        'road_fees': 'Road fees',
        'weighbridge': 'Weighbridge',
        'loading': 'Loading',
        'unloading': 'Unloading',
        'fines': 'Fines',
        'emergency_maintenance': 'Emergency maintenance',
        'driver_advance': 'Driver advance',
        'other': 'Other',
      };

      final expectedAr = <String, String>{
        'fuel': 'وقود',
        'road_fees': 'رسوم طرق',
        'weighbridge': 'ميزان',
        'loading': 'تحميل',
        'unloading': 'تفريغ',
        'fines': 'غرامات',
        'emergency_maintenance': 'صيانة طارئة',
        'driver_advance': 'عهدة سائق',
        'other': 'أخرى',
      };

      for (final entry in expectedEn.entries) {
        expect(en.tripExpenseTypeName(entry.key), entry.value);
      }

      for (final entry in expectedAr.entries) {
        expect(ar.tripExpenseTypeName(entry.key), entry.value);
      }

      expect(en.tripExpenseTypeName('Road Fees'), 'Road fees');
      expect(ar.tripExpenseTypeName('Road Fees'), 'رسوم طرق');

      expect(en.tripExpenseTypeName('Custom Fee'), 'Custom Fee');
      expect(ar.tripExpenseTypeName('Custom Fee'), 'Custom Fee');
    });

    test('maps audit actions and preserves unknown action', () {
      final expectedEn = <String, String>{
        'created': 'Created',
        'updated': 'Updated',
        'status_changed': 'Status changed',
        'deactivated': 'Deactivated',
        'reactivated': 'Reactivated',
      };

      final expectedAr = <String, String>{
        'created': 'تم الإنشاء',
        'updated': 'تم التعديل',
        'status_changed': 'تم تغيير الحالة',
        'deactivated': 'تم إلغاء التفعيل',
        'reactivated': 'تمت إعادة التفعيل',
      };

      for (final entry in expectedEn.entries) {
        expect(en.tripAuditActionLabel(entry.key), entry.value);
      }

      for (final entry in expectedAr.entries) {
        expect(ar.tripAuditActionLabel(entry.key), entry.value);
      }

      expect(en.tripAuditActionLabel('custom_action'), 'custom_action');
      expect(ar.tripAuditActionLabel('custom_action'), 'custom_action');
    });

    test(
      'maps audit roles and preserves null, empty, and unknown behavior',
      () {
        final expectedEn = <String, String>{
          'owner': 'Owner',
          'admin': 'Admin',
          'operations': 'Operations',
          'accountant': 'Accountant',
          'viewer': 'Viewer',
          'driver': 'Driver',
        };

        final expectedAr = <String, String>{
          'owner': 'مالك',
          'admin': 'مدير',
          'operations': 'تشغيل',
          'accountant': 'محاسب',
          'viewer': 'مشاهد',
          'driver': 'سائق',
        };

        for (final entry in expectedEn.entries) {
          expect(en.tripAuditRoleLabel(entry.key), entry.value);
        }

        for (final entry in expectedAr.entries) {
          expect(ar.tripAuditRoleLabel(entry.key), entry.value);
        }

        expect(en.tripAuditRoleLabel(null), '-');
        expect(ar.tripAuditRoleLabel(null), '-');
        expect(en.tripAuditRoleLabel(''), '-');
        expect(ar.tripAuditRoleLabel(''), '-');

        expect(en.tripAuditRoleLabel('custom_role'), 'custom_role');
        expect(ar.tripAuditRoleLabel('custom_role'), 'custom_role');
      },
    );

    test('maps audit field labels and preserves unknown key', () {
      expect(en.tripAuditFieldLabel('customer_id'), 'Customer');
      expect(ar.tripAuditFieldLabel('customer_id'), 'العميل');

      expect(en.tripAuditFieldLabel('expense_id'), 'Expense id');
      expect(ar.tripAuditFieldLabel('expense_id'), 'معرّف المصروف');

      expect(
        en.tripAuditFieldLabel('tractor_head_plate_number'),
        'Tractor plate',
      );
      expect(
        ar.tripAuditFieldLabel('tractor_head_plate_number'),
        'رقم رأس الجرار',
      );

      expect(en.tripAuditFieldLabel('trailer_plate_number'), 'Trailer plate');
      expect(ar.tripAuditFieldLabel('trailer_plate_number'), 'رقم المقطورة');

      expect(en.tripAuditFieldLabel('custom_key'), 'custom_key');
      expect(ar.tripAuditFieldLabel('custom_key'), 'custom_key');
    });

    test('uses generated placeholders with exact existing wording', () {
      expect(en.tripCurrentStatusLine('Loaded'), 'Current status: Loaded');
      expect(
        ar.tripCurrentStatusLine('تم التحميل'),
        'الحالة الحالية: تم التحميل',
      );

      expect(
        en.tripStatusHistoryLine('Created', 'Assigned'),
        'From Created to Assigned',
      );
      expect(ar.tripStatusHistoryLine('جديدة', 'مخصصة'), 'من جديدة إلى مخصصة');

      expect(
        en.tripChangedByLine('Mina', 'Admin', '2026-08-23'),
        'Mina (Admin) - 2026-08-23',
      );
      expect(
        ar.tripChangedByLine('Mina', 'مدير', '2026-08-23'),
        'Mina (مدير) - 2026-08-23',
      );

      expect(
        en.tripAuditTimelineHeader('Mina', 'Admin', '2026-08-23'),
        'Mina (Admin) - 2026-08-23',
      );
      expect(
        ar.tripAuditTimelineHeader('Mina', 'مدير', '2026-08-23'),
        'Mina (مدير) - 2026-08-23',
      );

      expect(
        en.tripAuditChangeLine('Status', 'Created', 'Assigned'),
        'Status: from Created to Assigned',
      );
      expect(
        ar.tripAuditChangeLine('الحالة', 'جديدة', 'مخصصة'),
        'الحالة: من جديدة إلى مخصصة',
      );

      expect(en.tripAuditDetailLine('Amount', '100'), 'Amount: 100');
      expect(ar.tripAuditDetailLine('المبلغ', '100'), 'المبلغ: 100');
    });

    test('preserves bidi isolation in trip titles', () {
      const safeName = '\u2068TRIP-001\u2069';

      expect(en.tripDetailsTitle('TRIP-001'), 'Trip details: $safeName');
      expect(ar.tripDetailsTitle('TRIP-001'), 'تفاصيل الرحلة: $safeName');

      expect(
        en.tripUpdateStatusTitle('TRIP-001'),
        'Update trip status: $safeName',
      );
      expect(
        ar.tripUpdateStatusTitle('TRIP-001'),
        'تحديث حالة الرحلة: $safeName',
      );
    });

    test('maps audit values and preserves passthrough behavior', () {
      expect(en.tripAuditValueLabel('status', 'created'), 'Created');
      expect(ar.tripAuditValueLabel('status', 'created'), 'جديدة');

      expect(en.tripAuditValueLabel('paid_by', 'company'), 'Company');
      expect(ar.tripAuditValueLabel('paid_by', 'company'), 'الشركة');

      expect(en.tripAuditValueLabel('expense_name', 'fuel'), 'Fuel');
      expect(ar.tripAuditValueLabel('expense_name', 'fuel'), 'وقود');

      expect(
        en.tripAuditValueLabel('expense_type_name', 'Road Fees'),
        'Road fees',
      );
      expect(
        ar.tripAuditValueLabel('expense_type_name', 'Road Fees'),
        'رسوم طرق',
      );

      expect(en.tripAuditValueLabel('notes', null), '-');
      expect(ar.tripAuditValueLabel('notes', null), '-');

      expect(en.tripAuditValueLabel('amount', 125.5), '125.5');
      expect(ar.tripAuditValueLabel('amount', 125.5), '125.5');
    });
  });
}
