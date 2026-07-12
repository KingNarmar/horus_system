import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
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

    return AlertDialog(
      title: Text(strings.details),
      content: SizedBox(
        width: AppSizes.detailsDialogMaxWidth,
        child: settlement == null || state.isDetailsLoading
            ? const Center(child: CircularProgressIndicator())
            : state.detailsFailure != null
            ? _DetailsFailure(
                message: context.localizedDriverSettlementFailure(
                  state.detailsFailure!,
                ),
                onRetry: onRetry,
              )
            : SingleChildScrollView(
                child: _DetailsContent(state: state, settlement: settlement),
              ),
      ),
      actions: [
        if (settlement != null &&
            !state.isDetailsLoading &&
            state.canManageDriverSettlements &&
            settlement.status == DriverSettlementStatus.draft)
          FilledButton(
            onPressed: state.isPending(settlement.id)
                ? null
                : () => onFinalize(settlement),
            child: Text(
              state.isPending(settlement.id)
                  ? strings.finalizing
                  : strings.finalize,
            ),
          ),
        if (settlement != null &&
            !state.isDetailsLoading &&
            state.canManageDriverSettlements &&
            settlement.status != DriverSettlementStatus.voided)
          OutlinedButton(
            onPressed: state.isPending(settlement.id)
                ? null
                : () => onVoid(settlement),
            child: Text(
              state.isPending(settlement.id) ? strings.voiding : strings.void,
            ),
          ),
        TextButton(
          onPressed: state.pendingActionSettlementId == null
              ? () => Navigator.of(context).pop()
              : null,
          child: Text(context.l10n.cancelButton),
        ),
      ],
    );
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
        Text(
          driverName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.labelValue(
            strings.period,
            strings.periodValue(
              formatDriverSettlementDate(
                settlement.period.start,
                localeName,
              ),
              formatDriverSettlementDate(settlement.period.end, localeName),
            ),
          ),
        ),
        Text(
          strings.labelValue(
            strings.status,
            context.driverSettlementStatusLabel(settlement.status),
          ),
        ),
        if (settlement.createdAt != null)
          Text(
            strings.labelValue(
              strings.createdAt,
              formatDriverSettlementDateTime(
                settlement.createdAt!,
                localeName,
              ),
            ),
          ),
        if (settlement.finalizedAt != null)
          Text(
            strings.labelValue(
              strings.finalizedAt,
              formatDriverSettlementDateTime(
                settlement.finalizedAt!,
                localeName,
              ),
            ),
          ),
        if (settlement.voidedAt != null)
          Text(
            strings.labelValue(
              strings.voidedAt,
              formatDriverSettlementDateTime(
                settlement.voidedAt!,
                localeName,
              ),
            ),
          ),
        if (settlement.voidReason != null)
          Text(
            strings.labelValue(strings.voidReason, settlement.voidReason!),
          ),
        if (settlement.notes != null && settlement.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(strings.labelValue(strings.notes, settlement.notes!)),
        ],
        const SizedBox(height: AppSpacing.lg),
        DriverSettlementCalculationSection(
          calculation: settlement.calculation,
        ),
        const SizedBox(height: AppSpacing.lg),
        DriverSettlementItemsSection(items: settlement.items),
        const SizedBox(height: AppSpacing.lg),
        _SettlementActivity(state: state),
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

class _SettlementActivity extends StatelessWidget {
  final DriverSettlementsLoaded state;

  const _SettlementActivity({required this.state});

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.activityTimeline,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.isActivityLoading)
          Text(strings.loadingActivity)
        else if (state.activityFailure != null)
          Text(
            context.localizedDriverSettlementFailure(state.activityFailure!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else if (state.selectedSettlementActivity.isEmpty)
          Text(strings.noActivity)
        else
          ...state.selectedSettlementActivity.map(
            (log) => _AuditLogCard(log: log),
          ),
      ],
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
