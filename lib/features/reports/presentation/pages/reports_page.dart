import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/network/presentation/widgets/network_reconnect_refresh_boundary.dart';
import '../../../../core/utils/business_date_date_time_adapter.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/report_date_range.dart';
import '../cubit/report_type.dart';
import '../cubit/report_export_cubit.dart';
import '../cubit/report_export_state.dart';
import '../../domain/repositories/report_pdf_delivery_repository.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../helpers/reports_failure_message.dart';
import '../helpers/reports_formatters.dart';
import '../helpers/reports_presentation_constants.dart';
import '../localization/reports_localizations.dart';
import '../localization/report_export_labels_x.dart';
import '../widgets/open_invoices_report_view.dart';
import '../widgets/report_export_actions.dart';
import '../widgets/report_pdf_preview_dialog.dart';
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
  BusinessDate? _fromDate;
  BusinessDate? _toDate;
  late ReportType _reportType;
  DialogRoute<void>? _activePreviewRoute;

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

    _dismissPreview();
    context.read<ReportExportCubit>().invalidate();
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
  void dispose() {
    _dismissPreview();
    super.dispose();
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

    return BlocListener<ReportExportCubit, ReportExportState>(
      listener: _handleExportState,
      child: NetworkReconnectRefreshBoundary(
        onReconnect: () async => _load(),
        child: Column(
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
            BlocBuilder<ReportExportCubit, ReportExportState>(
              builder: (context, exportState) =>
                  BlocBuilder<ReportsCubit, ReportsState>(
                    builder: (context, state) => _ReportsStateView(
                      state: state,
                      onRetry: _load,
                      onExport: _export,
                      isExportBusy: exportState is ReportExportBusy,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExportState(BuildContext context, ReportExportState state) {
    if (!context.mounted) return;
    final exportCubit = context.read<ReportExportCubit>();
    if (state is ReportExportPreviewReady ||
        state is ReportExportPrintPreviewReady) {
      _dismissPreview();
      final printReady = state is ReportExportPrintPreviewReady;
      final bytes = state is ReportExportPrintPreviewReady
          ? state.document.bytes
          : (state as ReportExportPreviewReady).bytes;
      final pageLayout = state is ReportExportPrintPreviewReady
          ? state.document.pageLayout
          : null;
      final route = DialogRoute<void>(
        context: context,
        builder: (_) => ReportPdfPreviewDialog(
          bytes: bytes,
          pageLayout: pageLayout,
          onConfirmPrint: printReady ? _confirmPrint : null,
        ),
      );
      _activePreviewRoute = route;
      unawaited(
        Navigator.of(context, rootNavigator: true).push(route).whenComplete(() {
          if (identical(_activePreviewRoute, route)) {
            _activePreviewRoute = null;
          }
          if (printReady) exportCubit.cancelPrintPreview();
        }),
      );
      if (!printReady) exportCubit.clearFeedback();
      return;
    }

    final strings = context.reportsL10n;
    String? message;
    if (state is ReportExportFailed) {
      message = reportsFailureMessage(context, state.failure);
    } else if (state is ReportExportCompleted) {
      message = switch (state.outcome) {
        ReportPdfDeliveryOutcome.cancelled => null,
        ReportPdfDeliveryOutcome.initiated => strings.exportPdfShareInitiated,
        ReportPdfDeliveryOutcome.completed => strings.exportPdfCompleted,
      };
    }
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    if (state is ReportExportFailed || state is ReportExportCompleted) {
      exportCubit.clearFeedback();
    }
  }

  void _confirmPrint() {
    _dismissPreview();
    unawaited(
      context.read<ReportExportCubit>().confirmPrint(
        currentCompanyContext: widget.currentCompanyContext,
      ),
    );
  }

  void _export(ReportsLoaded loaded, ReportPdfAction action) {
    context.read<ReportExportCubit>().perform(
      action: action,
      currentCompanyContext: widget.currentCompanyContext,
      kind: loaded.reportType.exportKind,
      dateRange: loaded.dateRange,
      labels: context.reportExportLabels,
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
    _dismissPreview();
    context.read<ReportExportCubit>().invalidate();
    context.read<ReportsCubit>().load(
      currentCompanyContext: widget.currentCompanyContext,
      reportType: _reportType,
      dateRange: ReportDateRange(fromDate: _fromDate, toDate: _toDate),
    );
  }

  void _dismissPreview() {
    final route = _activePreviewRoute;
    _activePreviewRoute = null;
    final navigator = route?.navigator;
    if (route != null &&
        navigator != null &&
        navigator.mounted &&
        route.isActive) {
      navigator.removeRoute(route);
    }
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
    final initialDate = current == null
        ? now
        : BusinessDateDateTimeAdapter.toDateTime(current);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected == null || !mounted) return;
    final businessDate = BusinessDateDateTimeAdapter.fromDateTime(selected);
    setState(() {
      if (isFrom) {
        _fromDate = businessDate;
      } else {
        _toDate = businessDate;
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
  final void Function(ReportsLoaded, ReportPdfAction) onExport;
  final bool isExportBusy;

  const _ReportsStateView({
    required this.state,
    required this.onRetry,
    required this.onExport,
    required this.isExportBusy,
  });

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
          ReportExportActions(
            isBusy: isExportBusy,
            onAction: (action) => onExport(currentState, action),
          ),
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
