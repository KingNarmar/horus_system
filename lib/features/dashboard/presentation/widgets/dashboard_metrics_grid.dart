import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/app_breakpoints.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../helpers/dashboard_formatters.dart';
import '../localization/dashboard_localizations.dart';
import 'dashboard_metric_card.dart';

final class DashboardMetricsGrid extends StatelessWidget {
  static const int _mobileColumns = 1;
  static const int _tabletColumns = 2;
  static const int _desktopColumns = 3;

  final DashboardSummary summary;

  const DashboardMetricsGrid({required this.summary, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.dashboardL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final metrics = <_DashboardMetricViewData>[
      _DashboardMetricViewData(
        title: strings.todayTrips,
        value: summary.todayTrips.toString(),
        icon: AppIcons.trips,
      ),
      _DashboardMetricViewData(
        title: strings.runningTrips,
        value: summary.runningTrips.toString(),
        icon: AppIcons.tripsSelected,
      ),
      _DashboardMetricViewData(
        title: strings.deliveredTrips,
        value: summary.deliveredTrips.toString(),
        icon: AppIcons.statusUpdate,
      ),
      _DashboardMetricViewData(
        title: strings.availableVehicles,
        value: summary.availableVehicles.toString(),
        icon: AppIcons.fleet,
      ),
      _DashboardMetricViewData(
        title: strings.vehiclesOnTrip,
        value: summary.vehiclesOnTrip.toString(),
        icon: AppIcons.fleetSelected,
      ),
      _DashboardMetricViewData(
        title: strings.totalRevenue,
        value: formatDashboardMoney(
          money: summary.totalRevenue,
          fractionDigits: summary.baseCurrencyFractionDigits,
          localeName: localeName,
        ),
        icon: AppIcons.invoices,
      ),
      _DashboardMetricViewData(
        title: strings.totalExpenses,
        value: formatDashboardMoney(
          money: summary.totalExpenses,
          fractionDigits: summary.baseCurrencyFractionDigits,
          localeName: localeName,
        ),
        icon: AppIcons.expenses,
      ),
      _DashboardMetricViewData(
        title: strings.netProfit,
        value: formatDashboardMoney(
          money: summary.netProfit,
          fractionDigits: summary.baseCurrencyFractionDigits,
          localeName: localeName,
        ),
        icon: AppIcons.reports,
      ),
      _DashboardMetricViewData(
        title: strings.unpaidInvoices,
        value: summary.unpaidInvoices.toString(),
        icon: AppIcons.payments,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);
        final horizontalSpacing = AppSpacing.lg * (columns - 1);
        final cardWidth = (constraints.maxWidth - horizontalSpacing) / columns;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: cardWidth,
                  child: DashboardMetricCard(
                    title: metric.title,
                    value: metric.value,
                    icon: metric.icon,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  int _columnsForWidth(double width) {
    return switch (AppBreakpoints.deviceTypeForWidth(width)) {
      AppDeviceType.mobile => _mobileColumns,
      AppDeviceType.tablet => _tabletColumns,
      AppDeviceType.desktop => _desktopColumns,
    };
  }
}

final class _DashboardMetricViewData {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardMetricViewData({
    required this.title,
    required this.value,
    required this.icon,
  });
}
