import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/vehicle_status.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_state.dart';
import '../widgets/fleet_asset_cards.dart';
import '../widgets/fleet_filters.dart';
import '../widgets/fleet_form_dialog.dart';

class FleetPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const FleetPage({required this.currentCompanyContext, super.key});

  @override
  State<FleetPage> createState() => _FleetPageState();
}

class _FleetPageState extends State<FleetPage> {
  @override
  void initState() {
    super.initState();
    context.read<FleetCubit>().loadFleet(widget.currentCompanyContext);
  }

  Future<void> _openTractorHeadForm({TractorHead? tractorHead}) async {
    final l10n = context.l10n;

    await showDialog<void>(
      context: context,
      builder: (_) => FleetFormDialog(
        title: tractorHead == null
            ? l10n.addTractorHeadButton
            : l10n.editTractorHeadTitle,
        initialPlateNumber: tractorHead?.plateNumber,
        initialStatus: tractorHead?.status ?? VehicleStatus.available,
        initialLicenseExpiryDate: tractorHead?.licenseExpiryDate,
        initialExpectedFuelConsumption: tractorHead?.expectedFuelConsumption,
        initialNotes: tractorHead?.notes,
        notesLabel: l10n.vehicleNotesLabel,
        showExpectedFuelConsumption: true,
        onSubmit: (data) => context.read<FleetCubit>().saveTractorHead(
          tractorHead: tractorHead,
          plateNumber: data.plateNumber,
          status: data.status,
          licenseExpiryDate: data.licenseExpiryDate,
          expectedFuelConsumption: data.expectedFuelConsumption,
          notes: data.notes,
        ),
      ),
    );
  }

  Future<void> _openTrailerForm({TrailerEntity? trailer}) async {
    final l10n = context.l10n;

    await showDialog<void>(
      context: context,
      builder: (_) => FleetFormDialog(
        title: trailer == null ? l10n.addTrailerButton : l10n.editTrailerTitle,
        initialPlateNumber: trailer?.plateNumber,
        initialStatus: trailer?.status ?? VehicleStatus.available,
        initialLicenseExpiryDate: trailer?.licenseExpiryDate,
        initialNotes: trailer?.technicalNotes,
        notesLabel: l10n.technicalNotesLabel,
        onSubmit: (data) => context.read<FleetCubit>().saveTrailer(
          trailer: trailer,
          plateNumber: data.plateNumber,
          status: data.status,
          licenseExpiryDate: data.licenseExpiryDate,
          technicalNotes: data.notes,
        ),
      ),
    );
  }

  Future<void> _deactivateTractorHead(TractorHead item) async {
    final cubit = context.read<FleetCubit>();

    if (await _confirmActiveStateChange(isDeactivate: true)) {
      await cubit.deactivateTractorHead(item);
    }
  }

  Future<void> _reactivateTractorHead(TractorHead item) async {
    final cubit = context.read<FleetCubit>();

    if (await _confirmActiveStateChange(isDeactivate: false)) {
      await cubit.reactivateTractorHead(item);
    }
  }

  Future<void> _deactivateTrailer(TrailerEntity item) async {
    final cubit = context.read<FleetCubit>();

    if (await _confirmActiveStateChange(isDeactivate: true)) {
      await cubit.deactivateTrailer(item);
    }
  }

  Future<void> _reactivateTrailer(TrailerEntity item) async {
    final cubit = context.read<FleetCubit>();

    if (await _confirmActiveStateChange(isDeactivate: false)) {
      await cubit.reactivateTrailer(item);
    }
  }

  Future<bool> _confirmActiveStateChange({required bool isDeactivate}) async {
    final l10n = context.l10n;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDeactivate
              ? l10n.fleetConfirmDeactivateTitle
              : l10n.fleetConfirmReactivateTitle,
        ),
        content: Text(
          isDeactivate
              ? l10n.fleetConfirmDeactivateMessage
              : l10n.fleetConfirmReactivateMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isDeactivate
                  ? l10n.fleetDeactivateButton
                  : l10n.fleetReactivateButton,
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<FleetCubit, FleetState>(
      builder: (context, state) {
        final cubit = context.read<FleetCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.fleetTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (state is FleetLoaded && state.canManageFleet)
                  _AddButton(
                    selectedTab: state.selectedTab,
                    onAddTractorHead: () => _openTractorHeadForm(),
                    onAddTrailer: () => _openTrailerForm(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state is FleetInitial || state is FleetLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is FleetFailure)
              _MessageCard(
                message: l10n.localizedErrorMessage(state.failure),
                action: OutlinedButton(
                  onPressed: () =>
                      cubit.loadFleet(widget.currentCompanyContext),
                  child: Text(l10n.retryButton),
                ),
              )
            else if (state is FleetLoaded) ...[
              FleetFilters(
                selectedTab: state.selectedTab,
                statusFilter: state.statusFilter,
                onTabChanged: cubit.selectTab,
                onSearchChanged: cubit.setSearchQuery,
                onStatusFilterChanged: cubit.setStatusFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              _FleetAssetBody(
                state: state,
                onEditTractorHead: (item) =>
                    _openTractorHeadForm(tractorHead: item),
                onDeactivateTractorHead: _deactivateTractorHead,
                onReactivateTractorHead: _reactivateTractorHead,
                onEditTrailer: (item) => _openTrailerForm(trailer: item),
                onDeactivateTrailer: _deactivateTrailer,
                onReactivateTrailer: _reactivateTrailer,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  final FleetAssetTab selectedTab;
  final VoidCallback onAddTractorHead;
  final VoidCallback onAddTrailer;

  const _AddButton({
    required this.selectedTab,
    required this.onAddTractorHead,
    required this.onAddTrailer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isTractorHead = selectedTab == FleetAssetTab.tractorHeads;

    return FilledButton.icon(
      onPressed: isTractorHead ? onAddTractorHead : onAddTrailer,
      icon: const Icon(AppIcons.add),
      label: Text(
        isTractorHead ? l10n.addTractorHeadButton : l10n.addTrailerButton,
      ),
    );
  }
}

class _FleetAssetBody extends StatelessWidget {
  final FleetLoaded state;
  final ValueChanged<TractorHead> onEditTractorHead;
  final ValueChanged<TractorHead> onDeactivateTractorHead;
  final ValueChanged<TractorHead> onReactivateTractorHead;
  final ValueChanged<TrailerEntity> onEditTrailer;
  final ValueChanged<TrailerEntity> onDeactivateTrailer;
  final ValueChanged<TrailerEntity> onReactivateTrailer;

  const _FleetAssetBody({
    required this.state,
    required this.onEditTractorHead,
    required this.onDeactivateTractorHead,
    required this.onReactivateTractorHead,
    required this.onEditTrailer,
    required this.onDeactivateTrailer,
    required this.onReactivateTrailer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.selectedTab == FleetAssetTab.tractorHeads) {
      if (state.allTractorHeads.isEmpty) {
        return _MessageCard(message: l10n.noTractorHeadsFound);
      }

      if (state.tractorHeads.isEmpty) {
        return _MessageCard(message: l10n.noFleetMatchFilters);
      }

      return TractorHeadCards(
        tractorHeads: state.tractorHeads,
        canManageFleet: state.canManageFleet,
        isActionLoading: state.isActiveStateChanging,
        onEdit: onEditTractorHead,
        onDeactivate: onDeactivateTractorHead,
        onReactivate: onReactivateTractorHead,
      );
    }

    if (state.allTrailers.isEmpty) {
      return _MessageCard(message: l10n.noTrailersFound);
    }

    if (state.trailers.isEmpty) {
      return _MessageCard(message: l10n.noFleetMatchFilters);
    }

    return TrailerCards(
      trailers: state.trailers,
      canManageFleet: state.canManageFleet,
      isActionLoading: state.isActiveStateChanging,
      onEdit: onEditTrailer,
      onDeactivate: onDeactivateTrailer,
      onReactivate: onReactivateTrailer,
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final Widget? action;

  const _MessageCard({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
