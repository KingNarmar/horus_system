import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status_history.dart';
import '../cubit/trips_state.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';

class TripDetailsDialog extends StatelessWidget {
  final TripEntity trip;
  final TripsLoaded? state;

  const TripDetailsDialog({required this.trip, required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailsTrip = state?.selectedTrip?.id == trip.id
        ? state!.selectedTrip!
        : trip;

    return AlertDialog(
      title: Text(l10n.tripDetailsTitle(detailsTrip.displayName)),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(text: l10n.tripBasicInfo),
              _BasicInfoSection(trip: detailsTrip),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: l10n.tripAccountability),
              _AccountabilitySection(state: state),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: l10n.tripStatusHistoryTitle),
              _StatusHistorySection(state: state),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(text: l10n.tripActivityTimeline),
              _ActivityTimelineSection(state: state),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tripCloseButton),
        ),
      ],
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  final TripEntity trip;

  const _BasicInfoSection({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _DetailsCard(
      children: [
        _DetailRow(
          label: l10n.tripLoadingOrderHeader,
          value: TripFormatters.optionalText(
            trip.loadingOrderNumber,
            l10n.tripEmptyValue,
          ),
        ),
        _DetailRow(
          label: l10n.tripWaybillHeader,
          value: TripFormatters.optionalText(
            trip.waybillNumber,
            l10n.tripEmptyValue,
          ),
        ),
        _DetailRow(
          label: l10n.tripCustomerHeader,
          value: TripFormatters.optionalText(
            trip.customerName,
            l10n.tripEmptyValue,
          ),
        ),
        _DetailRow(
          label: l10n.tripRouteHeader,
          value: TripFormatters.optionalText(
            trip.routeName,
            l10n.tripEmptyValue,
          ),
        ),
        _DetailRow(
          label: l10n.tripDriverHeader,
          value: TripFormatters.optionalText(
            trip.driverName,
            l10n.tripEmptyValue,
          ),
        ),
        _DetailRow(
          label: l10n.tripVehicleHeader,
          value: TripFormatters.vehicleText(trip, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripQuantityHeader,
          value: TripFormatters.quantityTons(
            trip.quantityTons,
            l10n.tripEmptyValue,
            l10n.tripTonsSuffix,
          ),
        ),
        _DetailRow(
          label: l10n.tripFreightPriceHeader,
          value: TripFormatters.money(trip.freightPrice, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripTotalExpensesLabel,
          value: TripFormatters.money(trip.totalExpenses, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripNetProfitHeader,
          value: TripFormatters.money(trip.netProfit, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripStatusHeader,
          value: l10n.tripStatusLabel(trip.status),
        ),
        _DetailRow(
          label: l10n.tripScheduledLoadingAtLabel,
          value: _formatDateTime(trip.scheduledLoadingAt, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripScheduledDeliveryAtLabel,
          value: _formatDateTime(trip.scheduledDeliveryAt, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripActualLoadingAtLabel,
          value: _formatDateTime(trip.actualLoadingAt, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripActualDeliveryAtLabel,
          value: _formatDateTime(trip.actualDeliveryAt, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripNotesLabel,
          value: TripFormatters.optionalText(trip.notes, l10n.tripEmptyValue),
        ),
      ],
    );
  }
}

class _AccountabilitySection extends StatelessWidget {
  final TripsLoaded? state;

  const _AccountabilitySection({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state == null || state!.isActivityLoading) {
      return _DetailsCard(children: [Text(l10n.tripLoadingActivity)]);
    }

    final failure = state!.activityFailure;
    if (failure != null) return _FailureText(failure: failure);

    final activity = state!.selectedTripActivity;
    final created = _firstCreatedAuditLog(activity);
    final latest = activity.isEmpty ? null : activity.first;

    return _DetailsCard(
      children: [
        _DetailRow(
          label: l10n.tripCreatedBy,
          value: created?.actorDisplayName ?? l10n.tripUnknownUser,
        ),
        _DetailRow(
          label: l10n.tripCreatedRole,
          value: l10n.tripAuditRoleLabel(created?.actorRole),
        ),
        _DetailRow(
          label: l10n.tripCreatedAt,
          value: _formatDateTime(created?.createdAt, l10n.tripEmptyValue),
        ),
        _DetailRow(
          label: l10n.tripLastActivityBy,
          value: latest?.actorDisplayName ?? l10n.tripUnknownUser,
        ),
        _DetailRow(
          label: l10n.tripLastActivityRole,
          value: l10n.tripAuditRoleLabel(latest?.actorRole),
        ),
        _DetailRow(
          label: l10n.tripLastActivityAt,
          value: _formatDateTime(latest?.createdAt, l10n.tripEmptyValue),
        ),
      ],
    );
  }
}

class _StatusHistorySection extends StatelessWidget {
  final TripsLoaded? state;

  const _StatusHistorySection({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state == null || state!.isStatusHistoryLoading) {
      return _DetailsCard(children: [Text(l10n.tripLoadingStatusHistory)]);
    }

    final failure = state!.statusHistoryFailure;
    if (failure != null) return _FailureText(failure: failure);

    final history = state!.selectedTripStatusHistory;
    if (history.isEmpty) {
      return _DetailsCard(children: [Text(l10n.tripNoStatusHistoryFound)]);
    }

    return Column(
      children: history.map((item) => _StatusHistoryItem(item: item)).toList(),
    );
  }
}

class _ActivityTimelineSection extends StatelessWidget {
  final TripsLoaded? state;

  const _ActivityTimelineSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state == null || state!.isActivityLoading) {
      return _DetailsCard(children: [Text(l10n.tripLoadingActivity)]);
    }

    final failure = state!.activityFailure;
    if (failure != null) return _FailureText(failure: failure);

    final activity = state!.selectedTripActivity;
    if (activity.isEmpty) {
      return _DetailsCard(children: [Text(l10n.tripNoActivityFound)]);
    }

    return Column(
      children: activity.map((log) => _ActivityTimelineItem(log: log)).toList(),
    );
  }
}

class _StatusHistoryItem extends StatelessWidget {
  final TripStatusHistory item;

  const _StatusHistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tripStatusHistoryLine(
                item.oldStatus == null
                    ? l10n.tripEmptyValue
                    : l10n.tripStatusLabel(item.oldStatus!),
                l10n.tripStatusLabel(item.newStatus),
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.tripChangedByLine(
                item.changedByName ?? l10n.tripUnknownUser,
                l10n.tripAuditRoleLabel(item.changedByRole),
                _formatDateTime(item.changedAt, l10n.tripEmptyValue),
              ),
            ),
            if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(item.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final AuditLog log;

  const _ActivityTimelineItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = log.actorDisplayName ?? l10n.tripUnknownUser;
    final role = l10n.tripAuditRoleLabel(log.actorRole);
    final date = _formatDateTime(log.createdAt, l10n.tripEmptyValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(AppIcons.auditHistory),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.tripAuditActionLabel(log.action.value),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.tripAuditTimelineHeader(actor, role, date)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_localizedAuditDescription(context, log)),
                  ..._changeLines(context, log),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _changeLines(BuildContext context, AuditLog log) {
    final l10n = context.l10n;
    final oldValues = log.oldValues ?? const <String, Object?>{};
    final newValues = log.newValues ?? const <String, Object?>{};

    final visibleKeys = <String>{
      ...oldValues.keys,
      ...newValues.keys,
    }.where((key) => key != 'id' && key != 'company_id').toList();

    if (visibleKeys.isEmpty) return const [];

    return [
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.tripChanges, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: AppSpacing.xs),
      ...visibleKeys.map((key) {
        return Text(
          l10n.tripAuditChangeLine(
            l10n.tripAuditFieldLabel(key),
            l10n.tripAuditValueLabel(key, oldValues[key]),
            l10n.tripAuditValueLabel(key, newValues[key]),
          ),
        );
      }),
    ];
  }
}

class _DetailsCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _FailureText extends StatelessWidget {
  final Failure failure;

  const _FailureText({required this.failure});

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      children: [Text(context.l10n.localizedErrorMessage(failure))],
    );
  }
}

AuditLog? _firstCreatedAuditLog(List<AuditLog> activity) {
  for (final log in activity.reversed) {
    if (log.action == AuditAction.created) return log;
  }
  return null;
}

String _localizedAuditDescription(BuildContext context, AuditLog log) {
  final l10n = context.l10n;
  final actionLabel = l10n.tripAuditActionLabel(log.action.value);
  final entityName = _firstText([
        log.entityDisplayName,
        log.newValues?['customer_name'],
        log.oldValues?['customer_name'],
        log.newValues?['route_name'],
        log.oldValues?['route_name'],
      ]) ??
      l10n.tripEmptyValue;

  if (log.action == AuditAction.statusChanged) {
    final oldStatus = l10n.tripAuditValueLabel(
      'status',
      log.metadata?['old_status'] ?? log.oldValues?['status'],
    );
    final newStatus = l10n.tripAuditValueLabel(
      'status',
      log.metadata?['new_status'] ?? log.newValues?['status'],
    );

    return l10n.tripAuditChangeLine(
      l10n.tripStatusHeader,
      oldStatus,
      newStatus,
    );
  }

  return '$actionLabel: $entityName';
}

String? _firstText(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }

  return null;
}

String _formatDateTime(DateTime? value, String emptyValue) {
  if (value == null) return emptyValue;

  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}
