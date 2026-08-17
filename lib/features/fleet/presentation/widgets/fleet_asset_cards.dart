import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_state.dart';
import '../localization/fleet_localizations_x.dart';
import 'fleet_details_dialog.dart';

part 'fleet_asset_actions.dart';
part 'fleet_asset_card.dart';
part 'fleet_asset_details_dialog_launcher.dart';
part 'fleet_asset_formatters.dart';
part 'fleet_asset_tables.dart';

class TractorHeadCards extends StatelessWidget {
  final List<TractorHead> tractorHeads;
  final bool canManageFleet;
  final bool Function(String id) isActionLoading;
  final ValueChanged<TractorHead> onEdit;
  final ValueChanged<TractorHead> onDeactivate;
  final ValueChanged<TractorHead> onReactivate;

  const TractorHeadCards({
    required this.tractorHeads,
    required this.canManageFleet,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
          return _TractorHeadsTable(view: this);
        }
        return _FleetCardsLayout(
          children: tractorHeads
              .map(
                (item) => _FleetAssetCard(
                  plateNumber: item.plateNumber,
                  status: context.l10n.vehicleStatusText(item.status),
                  isActive: item.isActive,
                  isActionLoading: isActionLoading(item.id),
                  licenseExpiryDate: item.licenseExpiryDate,
                  expectedFuelConsumption: item.expectedFuelConsumption,
                  notes: item.notes,
                  canManageFleet: canManageFleet,
                  onViewDetails: () => _openTractorHeadDetails(context, item),
                  onEdit: () => onEdit(item),
                  onDeactivate: () => onDeactivate(item),
                  onReactivate: () => onReactivate(item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class TrailerCards extends StatelessWidget {
  final List<TrailerEntity> trailers;
  final bool canManageFleet;
  final bool Function(String id) isActionLoading;
  final ValueChanged<TrailerEntity> onEdit;
  final ValueChanged<TrailerEntity> onDeactivate;
  final ValueChanged<TrailerEntity> onReactivate;

  const TrailerCards({
    required this.trailers,
    required this.canManageFleet,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
          return _TrailersTable(view: this);
        }
        return _FleetCardsLayout(
          children: trailers
              .map(
                (item) => _FleetAssetCard(
                  plateNumber: item.plateNumber,
                  status: context.l10n.vehicleStatusText(item.status),
                  isActive: item.isActive,
                  isActionLoading: isActionLoading(item.id),
                  licenseExpiryDate: item.licenseExpiryDate,
                  notes: item.technicalNotes,
                  canManageFleet: canManageFleet,
                  onViewDetails: () => _openTrailerDetails(context, item),
                  onEdit: () => onEdit(item),
                  onDeactivate: () => onDeactivate(item),
                  onReactivate: () => onReactivate(item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
