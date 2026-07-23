import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/widgets/adaptive_detail_row.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../cubit/driver_settlements_state.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';
import 'driver_settlement_calculation_section.dart';
import 'driver_settlement_items_section.dart';

class DriverSettlementDetailsDialog extends StatelessWidget {
  final DriverSettlementsLoaded state;
  final VoidCallback onRetry;
  final Future<void> Function(DriverSettlement settlement) onFinalize;
  final Future<void> Function(DriverSettlement settlement) onVoid;

  const DriverSettlementDetailsDialog({
    required this.state,
    required this.onRetry,
    required this.onFinalize,
    required this.onVoid,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final settlement = state.selectedSettlement;
    final canClose = state.pendingActionSettlementId == null;
    final isCompact =
        MediaQuery.sizeOf(context).width <= AppSizes.mobileMaxContentWidth;

    return Dialog(
      insetPadding: isCompact
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            )
          : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.detailsDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      strings.details,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.cancelButton,
                    onPressed: canClose
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildContent(context, settlement),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _buildActions(context, settlement, canClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    DriverSettlement? settlement,
    bool canClose,
  ) {
    final strings = context.driverSettlementsL10n;
    final actions = <Widget>[];

    if (settlement != null) {
      final isPending = state.isPending(settlement.id);

      if (_canFinalize(settlement)) {
        actions.add(
          FilledButton(
            key: const ValueKey('driverSettlementFinalizeButton'),
            onPressed: isPending ? null : () => onFinalize(settlement),
            child: Text(isPending ? strings.finalizing : strings.finalize),
          ),
        );
      }

      if (_canVoid(settlement)) {
        actions.add(
          OutlinedButton(
            key: const ValueKey('driverSettlementVoidButton'),
            onPressed: isPending ? null : () => onVoid(settlement),
            child: Text(isPending ? strings.voiding : strings.voidAction),
          ),
        );
      }
    }

    actions.add(
      TextButton(
        onPressed: canClose ? () => Navigator.of(context).pop() : null,
        child: Text(context.l10n.cancelButton),
      ),
    );

    return actions;
  }

  Widget _buildContent(BuildContext context, DriverSettlement? settlement) {
    if (settlement == null || state.isDetailsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final failure = state.detailsFailure;
    if (failure != null) {
      return _DetailsFailure(
        message: context.localizedDriverSettlementFailure(failure),
        onRetry: onRetry,
      );
    }

    return _DetailsContent(state: state, settlement: settlement);
  }

  bool _canFinalize(DriverSettlement settlement) {
    return !state.isDetailsLoading &&
        state.canManageDriverSettlements &&
        settlement.status == DriverSettlementStatus.draft;
  }

  bool _canVoid(DriverSettlement settlement) {
    return !state.isDetailsLoading &&
        state.canManageDriverSettlements &&
        settlement.status != DriverSettlementStatus.voided;
  }
}

class _DetailsContent extends StatelessWidget {
  final DriverSettlementsLoaded state;
  final DriverSettlement settlement;

  const _DetailsContent({required this.state, required this.settlement});

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final driverName =
        state.driverLabel(settlement.driverId) ?? strings.unknownDriver;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailsSection(
          title: driverName,
          children: [
            AdaptiveDetailRow(
              label: strings.period,
              value: strings.periodValue(
                formatDriverSettlementDate(settlement.period.start, localeName),
                formatDriverSettlementDate(settlement.period.end, localeName),
              ),
            ),
            AdaptiveDetailRow(
              label: strings.status,
              value: context.driverSettlementStatusLabel(settlement.status),
            ),
            if (settlement.createdAt != null)
              _DateTimeLine(
                label: strings.createdAt,
                value: settlement.createdAt!,
              ),
            if (settlement.finalizedAt != null)
              _DateTimeLine(
                label: strings.finalizedAt,
                value: settlement.finalizedAt!,
              ),
            if (settlement.voidedAt != null)
              _DateTimeLine(
                label: strings.voidedAt,
                value: settlement.voidedAt!,
              ),
            if (settlement.voidReason != null)
              AdaptiveDetailRow(
                label: strings.voidReason,
                value: settlement.voidReason!,
              ),
            if (settlement.notes != null && settlement.notes!.trim().isNotEmpty)
              AdaptiveDetailRow(label: strings.notes, value: settlement.notes!),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailsSection(
          title: strings.calculationBreakdown,
          children: [
            DriverSettlementCalculationSection(
              calculation: settlement.calculation,
              showTitle: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailsSection(
          title: strings.sourceItems,
          children: [
            DriverSettlementItemsSection(
              items: settlement.items,
              showTitle: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailsSection(
          title: strings.activityTimeline,
          children: [_SettlementActivityContent(state: state)],
        ),
        if (state.mutationFailure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.localizedDriverSettlementFailure(state.mutationFailure!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _DateTimeLine extends StatelessWidget {
  final String label;
  final DateTime value;

  const _DateTimeLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    return AdaptiveDetailRow(
      label: label,
      value: formatDriverSettlementDateTime(value, localeName),
    );
  }
}

class _SettlementActivityContent extends StatelessWidget {
  final DriverSettlementsLoaded state;

  const _SettlementActivityContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;

    if (state.isActivityLoading) {
      return Text(strings.loadingActivity);
    }

    if (state.activityFailure != null) {
      return Text(
        context.localizedDriverSettlementFailure(state.activityFailure!),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    if (state.selectedSettlementActivity.isEmpty) {
      return Text(strings.noActivity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.selectedSettlementActivity
          .map((log) => _AuditLogCard(log: log))
          .toList(growable: false),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog log;

  const _AuditLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final actor =
        log.actorDisplayName ?? log.actorEmail ?? context.l10n.unknownUser;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(context.driverSettlementAuditDescription(log)),
        subtitle: Text(
          strings.auditHeader(
            actor,
            context.localizedAuditRole(log.actorRole),
            formatDriverSettlementDateTime(log.createdAt, localeName),
          ),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailsFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailsFailure({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.retryButton),
        ),
      ],
    );
  }
}
