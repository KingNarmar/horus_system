import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../../domain/entities/company_expense.dart';
import '../cubit/company_expenses_state.dart';
import '../helpers/company_expense_date_formatter.dart';
import '../localization/company_expense_category_localizations_x.dart';

const _companyExpenseCreatedEvent = 'company_expense_created';
const _companyExpenseUpdatedEvent = 'company_expense_updated';
const _companyExpenseVoidedEvent = 'company_expense_voided';

class CompanyExpenseDetailsDialog extends StatelessWidget {
  final CompanyExpense expense;
  final CompanyExpensesLoaded? state;

  const CompanyExpenseDetailsDialog({
    required this.expense,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentState = state;
    final isSelectedExpense = currentState?.selectedExpense?.id == expense.id;
    final activity = isSelectedExpense
        ? currentState!.selectedExpenseActivity
        : const <AuditLog>[];
    final isLoading = isSelectedExpense &&
        (currentState?.isActivityLoading ?? false);
    final failure = isSelectedExpense ? currentState?.activityFailure : null;
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;
    final displayedExpense = isSelectedExpense
        ? currentState!.selectedExpense ?? expense
        : expense;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.detailsDialogMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.companyExpensesTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailsSection(
                title: l10n.fleetBasicInfo,
                children: [
                  _DetailRow(
                    label: l10n.companyExpenseCategoryLabel,
                    value: _categoryName(displayedExpense.categoryId, l10n),
                  ),
                  _DetailRow(
                    label: l10n.companyExpenseAmountLabel,
                    value: displayedExpense.amount.toStringAsFixed(2),
                  ),
                  _DetailRow(
                    label: l10n.companyExpenseDateLabel,
                    value: formatCompanyExpenseDate(displayedExpense.expenseDate),
                  ),
                  _DetailRow(
                    label: l10n.driverNameLabel,
                    value: _optional(
                      _driverLabel(displayedExpense.driverId),
                      l10n,
                    ),
                  ),
                  _DetailRow(
                    label: l10n.tractorHeadsTab,
                    value: _optional(
                      _tractorHeadLabel(displayedExpense.tractorHeadId),
                      l10n,
                    ),
                  ),
                  _DetailRow(
                    label: l10n.trailersTab,
                    value: _optional(
                      _trailerLabel(displayedExpense.trailerId),
                      l10n,
                    ),
                  ),
                  _DetailRow(
                    label: l10n.driverMovementTripLine,
                    value: _optional(_tripLabel(displayedExpense.tripId), l10n),
                  ),
                  _DetailRow(
                    label: l10n.companyExpenseReferenceLabel,
                    value: _optional(displayedExpense.referenceNumber, l10n),
                  ),
                  _DetailRow(
                    label: l10n.companyExpenseNotesLabel,
                    value: _optional(displayedExpense.notes, l10n),
                  ),
                  _DetailRow(
                    label: l10n.statusHeader,
                    value: displayedExpense.isVoided
                        ? l10n.companyExpenseVoidedStatus
                        : l10n.companyExpenseActiveStatus,
                  ),
                  if (displayedExpense.isVoided)
                    _DetailRow(
                      label: l10n.voidReasonLabel,
                      value: _optional(displayedExpense.voidReason, l10n),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.fleetAccountability,
                children: [
                  _DetailRow(
                    label: l10n.fleetCreatedBy,
                    value: _actorName(createdLog, l10n),
                  ),
                  _DetailRow(
                    label: l10n.fleetCreatedRole,
                    value: createdLog?.actorRole ?? l10n.fleetNotAvailable,
                  ),
                  _DetailRow(
                    label: l10n.fleetCreatedAt,
                    value: createdLog == null
                        ? l10n.fleetNotAvailable
                        : _formatDateTime(context, createdLog.createdAt),
                  ),
                  _DetailRow(
                    label: l10n.fleetLastActivityBy,
                    value: _actorName(latestLog, l10n),
                  ),
                  _DetailRow(
                    label: l10n.fleetLastActivityRole,
                    value: latestLog?.actorRole ?? l10n.fleetNotAvailable,
                  ),
                  _DetailRow(
                    label: l10n.fleetLastActivityAt,
                    value: latestLog == null
                        ? l10n.fleetNotAvailable
                        : _formatDateTime(context, latestLog.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.fleetActivityTimeline,
                children: [
                  if (isLoading)
                    Text(l10n.fleetLoadingActivity)
                  else if (failure != null)
                    Text(l10n.localizedErrorMessage(failure))
                  else if (activity.isEmpty)
                    Text(l10n.fleetNoActivityFound)
                  else
                    ...activity.map((log) => _ActivityTimelineItem(log: log)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AuditLog? _findOldestAction(List<AuditLog> logs, String action) {
    for (final log in logs.reversed) {
      if (log.action.value == action) return log;
    }
    return null;
  }

  String _categoryName(String categoryId, AppLocalizations l10n) {
    final categories = state?.categories ?? const [];
    for (final category in categories) {
      if (category.id == categoryId) {
        return l10n.companyExpenseCategoryName(
          code: category.code,
          fallbackName: category.name,
        );
      }
    }
    return l10n.fleetNotAvailable;
  }

  String? _driverLabel(String? id) => state?.driverLabel(id);

  String? _tractorHeadLabel(String? id) => state?.tractorHeadLabel(id);

  String? _trailerLabel(String? id) => state?.trailerLabel(id);

  String? _tripLabel(String? id) => state?.tripLabel(id);

  String _actorName(AuditLog? log, AppLocalizations l10n) {
    final name = log?.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log?.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.fleetUnknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? l10n.fleetNotAvailable
        : normalized;
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final AuditLog log;

  const _ActivityTimelineItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final changes = _changedFields(log, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _auditActionLabel(log, l10n),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            l10n.auditTimelineHeader(
              _actorName(log, l10n),
              log.actorRole ?? l10n.fleetNotAvailable,
              _formatDateTime(context, log.createdAt),
            ),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...changes,
          ],
        ],
      ),
    );
  }

  List<Widget> _changedFields(AuditLog log, AppLocalizations l10n) {
    const fields = [
      'category_id',
      'amount',
      'expense_date',
      'driver_id',
      'tractor_head_id',
      'trailer_id',
      'trip_id',
      'reference_number',
      'notes',
      'is_voided',
      'void_reason',
    ];
    final changes = AuditChangeBuilder.buildChanges(
      log: log,
      visibleKeys: fields,
      fieldLabelBuilder: (field) => _fieldLabel(field, l10n),
      valueLabelBuilder: (field, value) => _valueLabel(field, value, l10n),
    );
    return changes.map((change) {
      return Text(
        l10n.auditChangeLine(change.label, change.oldValue, change.newValue),
      );
    }).toList();
  }

  String _auditActionLabel(AuditLog log, AppLocalizations l10n) {
    final event = log.metadata?['audit_event']?.toString() ?? log.description;
    return switch (event) {
      _companyExpenseCreatedEvent => l10n.driverAuditActionCreated,
      _companyExpenseUpdatedEvent => l10n.driverAuditActionUpdated,
      _companyExpenseVoidedEvent => l10n.companyExpenseVoidedStatus,
      _ => switch (log.action.value) {
          'created' => l10n.driverAuditActionCreated,
          'updated' => l10n.driverAuditActionUpdated,
          'status_changed' => l10n.companyExpenseVoidedStatus,
          _ => log.action.value,
        },
    };
  }

  String _fieldLabel(String field, AppLocalizations l10n) {
    return switch (field) {
      'category_id' => l10n.companyExpenseCategoryLabel,
      'amount' => l10n.companyExpenseAmountLabel,
      'expense_date' => l10n.companyExpenseDateLabel,
      'driver_id' => l10n.driverNameLabel,
      'tractor_head_id' => l10n.tractorHeadsTab,
      'trailer_id' => l10n.trailersTab,
      'trip_id' => l10n.driverMovementTripLine,
      'reference_number' => l10n.companyExpenseReferenceLabel,
      'notes' => l10n.companyExpenseNotesLabel,
      'is_voided' => l10n.statusHeader,
      'void_reason' => l10n.voidReasonLabel,
      _ => field,
    };
  }

  String _valueLabel(String field, Object? value, AppLocalizations l10n) {
    if (field == 'is_voided') {
      return value == true
          ? l10n.companyExpenseVoidedStatus
          : l10n.companyExpenseActiveStatus;
    }

    final text = value?.toString().trim();
    return text == null || text.isEmpty ? l10n.fleetNotAvailable : text;
  }

  String _actorName(AuditLog log, AppLocalizations l10n) {
    final name = log.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.fleetUnknownUser;
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.detailsLabelWidth,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}
