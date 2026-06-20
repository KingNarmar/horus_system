import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../localization/trips_localizations_x.dart';

class TripActions extends StatelessWidget {
  final TripEntity trip;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool isChanging;
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canChangeStatus =
        canUpdateTripStatus && !trip.status.isTerminal && !isChanging;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        _TripActionButton(
          label: l10n.tripViewDetails,
          icon: AppIcons.view,
          onPressed: () => onViewDetails(trip),
        ),
        if (canManageTrips)
          _TripActionButton(
            label: l10n.tripEditButton,
            icon: AppIcons.edit,
            onPressed: isChanging ? null : () => onEdit(trip),
          ),
        if (canUpdateTripStatus)
          _TripActionButton(
            label: l10n.tripUpdateStatus,
            icon: AppIcons.statusUpdate,
            isLoading: isChanging,
            onPressed: canChangeStatus ? () => onUpdateStatus(trip) : null,
          ),
      ],
    );
  }
}

class _TripActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _TripActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: AppSizes.loadingIndicatorSm,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
              ),
            )
          : Icon(icon, size: AppSizes.iconSm),
      label: Text(label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
