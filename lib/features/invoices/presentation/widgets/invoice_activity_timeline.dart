import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../cubit/invoice_details_state.dart';
import '../helpers/invoice_formatters.dart';
import '../localization/invoice_failure_localizations_x.dart';
import '../localization/invoices_localizations.dart';

final class InvoiceActivityTimeline extends StatelessWidget {
  final InvoiceDetailsLoaded state;

  const InvoiceActivityTimeline({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;

    if (state.isActivityLoading) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: AppSizes.loadingIndicatorSm,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(strings.loadingActivity)),
        ],
      );
    }

    if (state.activityFailure != null) {
      return Text(context.localizedInvoiceFailure(state.activityFailure!));
    }

    if (state.activity.isEmpty) {
      return Text(strings.noActivity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...state.activity.map((log) => _AuditEntry(log: log))],
    );
  }
}

final class _AuditEntry extends StatelessWidget {
  final AuditLog log;

  const _AuditEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final actor =
        log.actorDisplayName ??
        log.actorEmail ??
        context.invoicesL10n.unavailableValue;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(AppIcons.auditHistory),
      title: Text(_auditDescription(context, log.description)),
      subtitle: Text(
        '$actor • ${formatInvoiceDateTime(log.createdAt, localeName)}',
      ),
    );
  }
}

String _auditDescription(BuildContext context, String description) {
  final strings = context.invoicesL10n;
  return switch (description) {
    'invoice_created' => strings.auditCreated,
    'invoice_updated' => strings.auditUpdated,
    'invoice_issued' => strings.auditIssued,
    'invoice_cancelled' => strings.auditCancelled,
    'invoice_payment_status_changed' => strings.auditPaymentStatusChanged,
    _ => strings.activity,
  };
}
