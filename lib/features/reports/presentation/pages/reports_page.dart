import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/report_date_range.dart';
import '../cubit/report_type.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../helpers/reports_failure_message.dart';
import '../helpers/reports_formatters.dart';
import '../helpers/reports_presentation_constants.dart';
import '../localization/reports_localizations.dart';
import '../widgets/open_invoices_report_view.dart';
import '../widgets/operational_report_view.dart';
import '../widgets/report_filters.dart';
import '../widgets/trip_expenses_report_view.dart';
import '../widgets/trip_net_profit_report_view.dart';

final class ReportsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const ReportsPage({required this.currentCompanyContext, super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

final class _ReportsPageState extends State<ReportsPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  late ReportType _reportType;

  List<ReportType> get _availableReports => ReportType.values
      .where((type) => type.canView(widget.currentCompanyContext.role))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _reportType = _availableReports.isEmpty
        ? ReportType.dailyTrips
        : _availableReports.first;
    if (_availableReports.isNotEmpty) {
      context.read<ReportsCubit>().load(
        currentCompanyContext: widget.currentCompanyContext,
        reportType: _reportType,
        dateRange: const ReportDateRange(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReportsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.currentCompanyContext;
    final newContext = widget.currentCompanyContext;
    if (oldContext.companyId == newContext.companyId &&
        oldContext.role == newContext.role) {
      return;
    }

    _fromDate = null;
    _toDate = null;
    _reportType = _availableReports.isEmpty
        ? ReportType.dailyTrips
        : _availableReports.first;
    if (_availableReports.isNotEmpty) {
      context.read<ReportsCubit>().load(
        currentCompanyContext: newContext,
        reportType: _reportType,
        dateRange: const ReportDateRange(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    if (_availableReports.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(text: strings.title),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(strings.noAccess),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(text: strings.title),
        const SizedBox(height: AppSpacing.lg),
        ReportFilters(
          role: widget.currentCompanyContext.role,
          reportType: _reportType,
          fromDate: _fromDate,
          toDate: _toDate,
          onReportChanged: _changeReport,
          onPickFromDate: () => _pickDate(isFrom: true),
          onPickToDate: () => _pickDate(isFrom: false),
          onApply: _load,
          onClearDates: _clearDates,
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, state) {
            return _ReportsStateView(state: state, onRetry: _load);
          },
        ),
      ],
    );
  }

  void _changeReport(ReportType value) {
    setState(() => _reportType = value);
    _load();
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _load();
  }

  void _load() {
    context.read<ReportsCubit>().load(
      currentCompanyContext: widget.currentCompanyContext,
      reportType: _reportType,
      dateRange: ReportDateRange(fromDate: _fromDate, toDate: _toDate),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final firstDate = DateTime(
      ReportsPresentationConstants.earliestSelectableYear,
    );
    final lastDate = DateTime(
      now.year + ReportsPresentationConstants.futureSelectableYears,
    );
    final current = isFrom ? _fromDate : _toDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _fromDate = selected;
      } else {
        _toDate = selected;
      }
    });
  }
}

final class _Title extends StatelessWidget {
  final String text;

  const _Title({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

final class _ReportsStateView extends StatelessWidget {
  final ReportsState state;
  final VoidCallback onRetry;

  const _ReportsStateView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final currentState = state;
    return switch (currentState) {
      ReportsInitial() || ReportsLoading() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(strings.loading),
          ],
        ),
      ),
      ReportsLoadFailure(:final failure) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reportsFailureMessage(context, failure)),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onRetry, child: Text(strings.retry)),
            ],
          ),
        ),
      ),
      ReportsLoaded(:final content, :final dateRange) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppliedPeriod(dateRange: dateRange),
          const SizedBox(height: AppSpacing.md),
          switch (content) {
            OperationalReportsContent(:final report) => OperationalReportView(
              report: report,
            ),
            TripExpensesReportsContent(:final report) => TripExpensesReportView(
              report: report,
            ),
            TripNetProfitReportsContent(:final report) =>
              TripNetProfitReportView(report: report),
            OpenInvoicesReportsContent(:final report) => OpenInvoicesReportView(
              report: report,
            ),
          },
        ],
      ),
    };
  }
}

final class _AppliedPeriod extends StatelessWidget {
  final ReportDateRange dateRange;

  const _AppliedPeriod({required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final from = dateRange.fromDate == null
        ? strings.allDates
        : formatReportDate(dateRange.fromDate!, localeName);
    final to = dateRange.toDate == null
        ? strings.allDates
        : formatReportDate(dateRange.toDate!, localeName);
    return Text(strings.dateRange(from, to));
  }
}
