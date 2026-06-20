import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../domain/entities/route_entity.dart';
import '../cubit/routes_cubit.dart';
import '../localization/routes_localizations_x.dart';

class RouteActivityDialog extends StatefulWidget {
  final RouteEntity route;

  const RouteActivityDialog({required this.route, super.key});

  @override
  State<RouteActivityDialog> createState() => _RouteActivityDialogState();
}

class _RouteActivityDialogState extends State<RouteActivityDialog> {
  late final Future<Result<List<AuditLog>>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = context.read<RoutesCubit>().getRouteActivity(
      widget.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.routeActivityTitle),
      content: SizedBox(
        width: 520,
        child: FutureBuilder<Result<List<AuditLog>>>(
          future: _activityFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final result = snapshot.data;
            if (result == null) {
              return Text(l10n.noRouteActivityFound);
            }

            return result.when(
              success: (logs) {
                if (logs.isEmpty) {
                  return Text(l10n.noRouteActivityFound);
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: logs
                        .map((log) => _RouteActivityTile(log: log))
                        .toList(),
                  ),
                );
              },
              failure: (failure) => Text(l10n.localizedErrorMessage(failure)),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.routeActivityCloseButton),
        ),
      ],
    );
  }
}

class _RouteActivityTile extends StatelessWidget {
  final AuditLog log;

  const _RouteActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = _actorName(log, l10n.emptyValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_actionLabel(log.action, l10n)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text('${l10n.routeActivityByLabel}: $actor'),
            Text(
              '${l10n.routeActivityAtLabel}: ${_formatDateTime(log.createdAt)}',
            ),
            if (log.description.trim().isNotEmpty) Text(log.description),
          ],
        ),
      ),
    );
  }
}

String _actorName(AuditLog log, String emptyValue) {
  final displayName = log.actorDisplayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;

  final email = log.actorEmail?.trim();
  if (email != null && email.isNotEmpty) return email;

  final role = log.actorRole?.trim();
  if (role != null && role.isNotEmpty) return role;

  final userId = log.actorUserId?.trim();
  if (userId != null && userId.isNotEmpty) return userId;

  return emptyValue;
}

String _actionLabel(AuditAction action, AppLocalizations l10n) {
  return switch (action) {
    AuditAction.created => l10n.routeActivityCreatedLabel,
    AuditAction.updated => l10n.routeActivityUpdatedLabel,
    AuditAction.deactivated => l10n.routeActivityDeactivatedLabel,
    AuditAction.reactivated => l10n.routeActivityReactivatedLabel,
    AuditAction.statusChanged => l10n.routeActivityStatusChangedLabel,
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');

  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
