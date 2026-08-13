import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:horus_system/features/dashboard/presentation/widgets/dashboard_metric_card.dart';
import 'package:horus_system/features/dashboard/presentation/widgets/dashboard_metrics_grid.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  for (final width in <double>[390, 800, 1200]) {
    testWidgets('renders all dashboard cards at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DashboardMetricsGrid(summary: _summary())),
        ),
      );

      expect(find.byType(DashboardMetricCard), findsNWidgets(9));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders Arabic dashboard cards in RTL', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DashboardMetricsGrid(summary: _summary())),
      ),
    );

    expect(find.byType(DashboardMetricCard), findsNWidgets(9));
    expect(find.text('رحلات اليوم'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('رحلات اليوم'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

DashboardSummary _summary() {
  final currency = CurrencyCode.tryParse('AED')!;
  return DashboardSummary(
    businessDate: DateTime(2026, 8, 12),
    baseCurrencyFractionDigits: 2,
    todayTrips: 0,
    runningTrips: 0,
    deliveredTrips: 3,
    availableVehicles: 2,
    vehiclesOnTrip: 1,
    unpaidInvoices: 0,
    totalRevenue: Money(minorUnits: 120000, currency: currency),
    totalExpenses: Money(minorUnits: 1731000, currency: currency),
    netProfit: Money(minorUnits: -1611000, currency: currency),
  );
}
