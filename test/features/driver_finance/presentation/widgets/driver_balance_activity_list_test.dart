import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity_entry.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_finance_trip_option.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:horus_system/features/driver_finance/presentation/widgets/driver_balance_activity_list.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('shows a traceable trip expense and its signed effect in $locale', (
      tester,
    ) async {
      final currency = CurrencyCode.tryParse('AED')!;
      final zero = Money(minorUnits: 0, currency: currency);
      final activity = DriverBalanceActivity(
        canonicalBalance: DriverMoneyBalance(
          companyId: 'company-1',
          driverId: 'driver-1',
          currency: currency,
          currencyFractionDigits: 2,
          totalAdvances: zero,
          totalDriverCharges: zero,
          totalTripExpenseCredits: zero,
          totalCashReturns: zero,
        ),
        entries: [
          DriverBalanceActivityEntry(
            source: DriverBalanceActivitySource.tripExpense,
            sourceId: 'ledger-expense-1',
            kind: DriverBalanceActivityKind.driverPaidTripExpense,
            companyId: 'company-1',
            driverId: 'driver-1',
            tripId: 'trip-1',
            businessDate: BusinessDate(year: 2026, month: 10, day: 21),
            createdAt: DateTime.utc(2026, 10, 21),
            amount: Money(minorUnits: 1250, currency: currency),
            description: 'Diesel',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DriverBalanceActivityList(
                activity: activity,
                tripOptions: const [
                  DriverFinanceTripOption(
                    id: 'trip-1',
                    label: 'TRP-2026-000006',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ledger-expense-1'), findsOneWidget);
      expect(find.textContaining('TRP-2026-000006'), findsOneWidget);
      expect(find.textContaining('Diesel'), findsOneWidget);
      expect(find.textContaining('12.50'), findsOneWidget);
      expect(
        Directionality.of(
          tester.element(find.textContaining('ledger-expense-1')),
        ),
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
}
