import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';
import '../../domain/entities/vehicle_status.dart';
import '../cubit/fleet_state.dart';
import '../localization/fleet_localizations_x.dart';

class FleetDetailsDialog extends StatelessWidget {
  final String assetId;
  final String plateNumber;
  final VehicleStatus status;
  final bool isActive;
  final DateTime? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String? notes;
  final String notesLabel;
  final FleetLoaded? state;

  const FleetDetailsDialog({required this.assetId, required this.plateNumber, required this.status, required this.isActive, required this.licenseExpiryDate, required this.notes, required this.notesLabel, required this.state, this.expectedFuelConsumption, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activity = state?.selectedAssetId == assetId ? state!.selectedAssetActivity : const <AuditLog>[];
    final isLoading = state?.selectedAssetId == assetId && (state?.isActivityLoading ?? false);
    final failure = state?.selectedAssetId == assetId ? state?.activityFailure : null;
    final createdLog = _findOldestAction(activity, AuditAction.created.value);
    final latestLog = activity.isEmpty ? null : activity.first;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.detailsDialogMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(child: Text(l10n.fleetDetailsTitle(plateNumber), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(AppIcons.clear)),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _Section(title: l10n.fleetBasicInfo, children: [
                _DetailRow(label: l10n.plateNumberLabel, value: plateNumber),
                _DetailRow(label: l10n.vehicleStatusLabel, value: l10n.vehicleStatusText(status)),
                _DetailRow(label: l10n.vehicleLicenseExpiryDateLabel, value: _dateOnlyOrEmpty(context, licenseExpiryDate)),
                if (expectedFuelConsumption != null) _DetailRow(label: l10n.expectedFuelConsumptionLabel, value: _numberText(expectedFuelConsumption!)),
                _DetailRow(label: notesLabel, value: _optional(notes, l10n)),
                _DetailRow(label: l10n.statusHeader, value: isActive ? l10n.activeStatus : l10n.inactiveStatus),
              ]),
              const SizedBox(height: AppSpacing.md),
              _Section(title: l10n.fleetAccountability, children: [
                _DetailRow(label: l10n.fleetCreatedBy, value: _actorName(createdLog, l10n)),
                _DetailRow(label: l10n.fleetCreatedRole, value: l10n.fleetAuditRoleLabel(createdLog?.actorRole)),
                _DetailRow(label: l10n.fleetCreatedAt, value: createdLog == null ? l10n.fleetNotAvailable : _formatDateTime(context, createdLog.createdAt)),
                _DetailRow(label: l10n.fleetLastActivityBy, value: _actorName(latestLog, l10n)),
                _DetailRow(label: l10n.fleetLastActivityRole, value: l10n.fleetAuditRoleLabel(latestLog?.actorRole)),
                _DetailRow(label: l10n.fleetLastActivityAt, value: latestLog == null ? l10n.fleetNotAvailable : _formatDateTime(context, latestLog.createdAt)),
              ]),
              const SizedBox(height: AppSpacing.md),
              _Section(title: l10n.fleetActivityTimeline, children: [
                if (isLoading)
                  Row(children: const [SizedBox(height: AppSizes.iconSm, width: AppSizes.iconSm, child: CircularProgressIndicator(strokeWidth: AppSizes.loadingIndicatorStrokeWidth)), SizedBox(width: AppSpacing.sm), _LoadingText()])
                else if (failure != null)
                  Text(l10n.localizedErrorMessage(failure))
                else if (activity.isEmpty)
                  Text(l10n.fleetNoActivityFound)
                else
                  ...activity.map((log) => _TimelineItem(log: log)),
              ]),
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
    return l10n.fleetUnknownUser;
  }

  String _optional(String? value, AppLocalizations l10n) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? l10n.emptyValue : normalized;
  }
}

class _LoadingText extends StatelessWidget {
  const _LoadingText();
  @override
  Widget build(BuildContext context) => Text(context.l10n.fleetLoadingActivity);
}

class _TimelineItem extends StatelessWidget {
  final AuditLog log;
  const _TimelineItem({required this.log});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const visibleKeys = ['plate_number', 'license_expiry_date', 'expected_fuel_consumption', 'status', 'notes', 'technical_notes', 'is_active'];
    final changes = AuditChangeBuilder.buildChanges(log: log, visibleKeys: visibleKeys, fieldLabelBuilder: l10n.fleetAuditFieldLabel, valueLabelBuilder: l10n.fleetAuditValueLabel);
    final actorName = log.actorDisplayName?.trim().isNotEmpty == true ? log.actorDisplayName!.trim() : (log.actorEmail?.trim().isNotEmpty == true ? log.actorEmail!.trim() : l10n.fleetUnknownUser);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.only(top: AppSpacing.xs), child: Icon(AppIcons.auditHistory, size: AppSizes.iconSm)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.fleetAuditActionLabel(log.action.value), style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(l10n.auditTimelineHeader(actorName, l10n.fleetAuditRoleLabel(log.actorRole), _formatDateTime(context, log.createdAt))),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.fleetChanges, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            ...changes.map((change) => Text(l10n.auditChangeLine(change.label, change.oldValue, change.newValue))),
          ],
        ])),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: AppSpacing.md), ...children])));
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: AppSizes.detailsLabelWidth, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value))]));
}

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final local = value.toLocal();
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

String _dateOnlyOrEmpty(BuildContext context, DateTime? value) {
  if (value == null) return context.l10n.emptyValue;
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _numberText(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
