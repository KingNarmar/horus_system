import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/driver.dart';
import '../cubit/drivers_state.dart';
import '../localization/drivers_localizations_x.dart';

class DriverDetailsDialog extends StatelessWidget {
  final Driver driver;
  final DriversLoaded? state;

  const DriverDetailsDialog({required this.driver, required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activity = state?.selectedDriver?.id == driver.id
        ? state!.selectedDriverActivity
        : const <AuditLog>[];
    final isLoading = state?.selectedDriver?.id == driver.id && (state?.isActivityLoading ?? false);
    final failure = state?.selectedDriver?.id == driver.id ? state?.activityFailure : null;
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
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
                      l10n.driverDetailsTitle(driver.fullName),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailsSection(
                title: l10n.basicInfo,
                children: [
                  _DetailRow(label: l10n.driverNameLabel, value: driver.fullName),
                  _DetailRow(label: l10n.phoneLabel, value: _optional(driver.phone, l10n)),
                  _DetailRow(label: l10n.nationalIdLabel, value: _optional(driver.nationalId, l10n)),
                  _DetailRow(label: l10n.licenseNumberLabel, value: _optional(driver.licenseNumber, l10n)),
                  _DetailRow(label: l10n.licenseExpiryDateLabel, value: driver.licenseExpiryDate == null ? l10n.emptyValue : _dateOnly(driver.licenseExpiryDate!)),
                  _DetailRow(label: l10n.notesLabel, value: _optional(driver.notes, l10n)),
                  _DetailRow(label: l10n.statusHeader, value: driver.isActive ? l10n.activeStatus : l10n.inactiveStatus),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.accountability,
                children: [
                  _DetailRow(label: l10n.createdBy, value: _actorName(createdLog, l10n)),
                  _DetailRow(label: l10n.createdRole, value: createdLog?.actorRole ?? l10n.notAvailable),
                  _DetailRow(label: l10n.createdAt, value: createdLog == null ? l10n.notAvailable : _formatDateTime(context, createdLog.createdAt)),
                  _DetailRow(label: l10n.lastActivityBy, value: _actorName(latestLog, l10n)),
                  _DetailRow(label: l10n.lastActivityRole, value: latestLog?.actorRole ?? l10n.notAvailable),
                  _DetailRow(label: l10n.lastActivityAt, value: latestLog == null ? l10n.notAvailable : _formatDateTime(context, latestLog.createdAt)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailsSection(
                title: l10n.activityTimeline,
                children: [
                  if (isLoading)
                    Text(l10n.loadingActivity)
                  else if (failure != null)
                    Text(failure.message)
                  else if (activity.isEmpty)
                    Text(l10n.noActivityFound)
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

  String _actorName(AuditLog? log, AppLocalizations l10n) {
    final name = log?.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log?.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.unknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? l10n.emptyValue : normalized;
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
          Text(l10n.auditActionLabel(log.action.value), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('${_actorName(log, l10n)} • ${_formatDateTime(context, log.createdAt)}'),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...changes,
          ],
        ],
      ),
    );
  }

  List<Widget> _changedFields(AuditLog log, AppLocalizations l10n) {
    final oldValues = log.oldValues;
    final newValues = log.newValues;
    if (oldValues == null || newValues == null) return const [];
    const fields = ['full_name', 'phone', 'national_id', 'license_number', 'license_expiry_date', 'notes', 'is_active'];
    return fields.where((field) => oldValues[field] != newValues[field]).map((field) {
      final oldValue = l10n.driverValueLabel(field, oldValues[field]);
      final newValue = l10n.driverValueLabel(field, newValues[field]);
      return Text('${l10n.driverFieldLabel(field)}: $oldValue → $newValue');
    }).toList();
  }

  String _actorName(AuditLog log, AppLocalizations l10n) {
    final name = log.actorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = log.actorEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return l10n.unknownUser;
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
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
          SizedBox(width: 190, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
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

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
