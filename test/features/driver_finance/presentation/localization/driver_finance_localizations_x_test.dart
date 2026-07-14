import 'package:horus_system/features/driver_finance/presentation/localization/driver_finance_localizations_x.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';
import 'package:test/test.dart';

void main() {
  group('DriverFinanceLocalizationsX.driverBalanceLabel', () {
    group('English', () {
      final l10n = AppLocalizationsEn();

      test('shows that the driver owes the company for a negative balance', () {
        expect(l10n.driverBalanceLabel(-400), 'Driver owes company: 400.00');
      });

      test('shows that the company owes the driver for a positive balance', () {
        expect(l10n.driverBalanceLabel(400), 'Company owes driver: 400.00');
      });

      test('shows a settled label for a zero balance', () {
        expect(l10n.driverBalanceLabel(0), 'Balance settled');
      });
    });

    group('Arabic', () {
      final l10n = AppLocalizationsAr();

      test('shows that the driver owes the company for a negative balance', () {
        expect(l10n.driverBalanceLabel(-400), 'السائق مدين للشركة: 400.00');
      });

      test('shows that the company owes the driver for a positive balance', () {
        expect(l10n.driverBalanceLabel(400), 'الشركة مدينة للسائق: 400.00');
      });

      test('shows a settled label for a zero balance', () {
        expect(l10n.driverBalanceLabel(0), 'الرصيد مسوّى');
      });
    });
  });
}
