import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';

class TripActions extends StatelessWidget {
  final TripEntity trip;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool isChanging;
  final bool showLabels;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onEdit;
  final ValueChanged<TripEntity> onUpdateStatus;

  const TripActions({
    required this.trip,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.isChanging,
    required this.onViewDetails,
    required this.onEdit,
    required this.onUpdateStatus,
    this.showLabels = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canChangeStatus =
        canUpdateTripStatus && !trip.status.isTerminal && !isChanging;

    final actions = [
      _TripActionData(
        label: l10n.tripViewDetails,
        icon: AppIcons.view,
        onPressed: () => onViewDetails(trip),
      ),
      if (canManageTrips)
        _TripActionData(
          label: l10n.tripEditButton,
          icon: AppIcons.edit,
          onPressed: isChanging ? null : () => onEdit(trip),
        ),
      if (canUpdateTripStatus)
        _TripActionData(
          label: l10n.tripUpdateStatus,
          icon: AppIcons.statusUpdate,
          isLoading: isChanging,
          onPressed: canChangeStatus ? () => onUpdateStatus(trip) : null,
        ),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final action in actions)
          showLabels
              ? _TripTextActionButton(action: action)
              : _TripIconActionButton(action: action),
      ],
    );
  }
}

class _TripActionData {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _TripActionData({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });
}

class _TripTextActionButton extends StatelessWidget {
  final _TripActionData action;

  const _TripTextActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: action.onPressed,
      icon: _ActionIcon(action: action),
      label: Text(action.label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _TripIconActionButton extends StatelessWidget {
  final _TripActionData action;

  const _TripIconActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: action.label,
      onPressed: action.onPressed,
      icon: _ActionIcon(action: action),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final _TripActionData action;

  const _ActionIcon({required this.action});

  @override
  Widget build(BuildContext context) {
    if (!action.isLoading) {
      return Icon(action.icon, size: AppSizes.iconSm);
    }

    return const SizedBox.square(
      dimension: AppSizes.loadingIndicatorSm,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
      ),
    );
  }
}
