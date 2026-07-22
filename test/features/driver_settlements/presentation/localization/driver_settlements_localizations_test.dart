import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/driver_settlements/presentation/localization/driver_settlements_localizations.dart';

void main() {
  test('provides English and Arabic driver settlement labels', () {
    final english = DriverSettlementsLocalizations.forLocale(
      const Locale('en'),
    );
    final arabic = DriverSettlementsLocalizations.forLocale(const Locale('ar'));

    expect(english.title, 'Driver settlements');
    expect(arabic.title, 'تسويات السائقين');
    expect(english.balanceDeduction, 'Salary recovery against driver debt');
    expect(arabic.balanceDeduction, 'استرداد دين السائق من الراتب');
    expect(arabic.statusVoided, 'مبطلة');
    expect(arabic.voidAction, 'إبطال');
    expect(arabic.voidTitle, 'إبطال التسوية');
    expect(arabic.voidReason, 'سبب الإبطال');
    expect(arabic.voidReasonRequired, 'سبب الإبطال مطلوب.');
    expect(arabic.auditVoided, 'تم إبطال التسوية');
    expect(arabic.settlementVoided, 'تم إبطال التسوية.');
    expect(english.itemDriverCharge, 'Driver charge');
    expect(arabic.itemCashReturn, 'نقدية أعادها السائق');
    expect(
      english.balanceRecoveryExceedsDebtFailure,
      "Salary recovery cannot exceed the driver's outstanding debt.",
    );
    expect(
      english.driverInactiveFailure,
      'Inactive drivers cannot be used for new settlements.',
    );
    expect(
      arabic.driverNotFoundFailure,
      'تعذر العثور على السائق المحدد داخل هذه الشركة.',
    );
    expect(english.periodValue('A', 'B'), 'A – B');
    expect(arabic.labelValue('الحالة', 'مسودة'), 'الحالة: مسودة');
  });
}
