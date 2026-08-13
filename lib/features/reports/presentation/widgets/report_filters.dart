import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/company_role.dart';
import '../cubit/report_type.dart';
import '../localization/reports_localizations.dart';
import '../helpers/reports_formatters.dart';

final class ReportFilters extends StatelessWidget {
  final CompanyRole role;
  final ReportType reportType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<ReportType> onReportChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onApply;
  final VoidCallback onClearDates;

  const ReportFilters({
    required this.role,
    required this.reportType,
    required this.fromDate,
    required this.toDate,
    required this.onReportChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onApply,
    required this.onClearDates,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final available = ReportType.values
        .where((type) => type.canView(role))
        .toList();
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < AppSizes.dataTableBreakpoint;
            final controls = <Widget>[
              DropdownButtonFormField<ReportType>(
                key: ValueKey(reportType),
                initialValue: reportType,
                decoration: InputDecoration(labelText: strings.reportLabel),
                items: available
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(strings.reportTypeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) onReportChanged(value);
                },
              ),
              _DateButton(
                label: strings.fromDate,
                value: fromDate == null
                    ? strings.selectDate
                    : formatReportDate(fromDate!, localeName),
                onPressed: onPickFromDate,
              ),
              _DateButton(
                label: strings.toDate,
                value: toDate == null
                    ? strings.selectDate
                    : formatReportDate(toDate!, localeName),
                onPressed: onPickToDate,
              ),
            ];

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...controls.expand(
                    (control) => [
                      control,
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _actionButtons(strings),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: controls
                      .map(
                        (control) => Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: AppSpacing.md,
                            ),
                            child: control,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _actionButtons(strings),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _actionButtons(ReportsLocalizations strings) {
    return [
      FilledButton.icon(
        onPressed: onApply,
        icon: const Icon(AppIcons.search),
        label: Text(strings.applyFilters),
      ),
      OutlinedButton.icon(
        onPressed: onClearDates,
        icon: const Icon(AppIcons.clear),
        label: Text(strings.clearFilters),
      ),
    ];
  }
}

final class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onPressed;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: InkWell(
        onTap: onPressed,
        child: Row(
          children: [
            const Icon(AppIcons.calendar),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }
}
