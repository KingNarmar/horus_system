part of 'fleet_asset_cards.dart';

Future<void> _openTractorHeadDetails(
  BuildContext context,
  TractorHead item,
) async {
  final fleetCubit = context.read<FleetCubit>();
  final documentCubit = context.read<FleetLicenseDocumentsCubit>();
  final loaded = fleetCubit.state;
  if (loaded is! FleetLoaded) return;

  fleetCubit.loadTractorHeadActivity(item);
  await documentCubit.load(
    currentCompanyContext: loaded.currentCompanyContext,
    target: FleetLicenseDocumentTarget(
      companyId: item.companyId,
      assetType: FleetAssetType.tractorHead,
      assetId: item.id,
    ),
  );
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: fleetCubit),
        BlocProvider.value(value: documentCubit),
      ],
      child: BlocBuilder<FleetCubit, FleetState>(
        builder: (context, state) {
          final current = _tractorHeadFromState(state, item.id);
          if (current == null) return _unavailableFleetDetailsDialog(context);
          return FleetDetailsDialog(
            assetId: current.id,
            plateNumber: current.plateNumber,
            status: current.status,
            isActive: current.isActive,
            licenseExpiryDate: current.licenseExpiryDate,
            expectedFuelConsumption: current.expectedFuelConsumption,
            notes: current.notes,
            notesLabel: context.l10n.vehicleNotesLabel,
            state: state is FleetLoaded ? state : null,
            onAssetChanged: () =>
                _refreshTractorHeadDetails(fleetCubit, current.id),
          );
        },
      ),
    ),
  );
  documentCubit.dismissDetails();
  fleetCubit.clearFleetAssetActivity();
}

Future<void> _openTrailerDetails(
  BuildContext context,
  TrailerEntity item,
) async {
  final fleetCubit = context.read<FleetCubit>();
  final documentCubit = context.read<FleetLicenseDocumentsCubit>();
  final loaded = fleetCubit.state;
  if (loaded is! FleetLoaded) return;

  fleetCubit.loadTrailerActivity(item);
  await documentCubit.load(
    currentCompanyContext: loaded.currentCompanyContext,
    target: FleetLicenseDocumentTarget(
      companyId: item.companyId,
      assetType: FleetAssetType.trailer,
      assetId: item.id,
    ),
  );
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: fleetCubit),
        BlocProvider.value(value: documentCubit),
      ],
      child: BlocBuilder<FleetCubit, FleetState>(
        builder: (context, state) {
          final current = _trailerFromState(state, item.id);
          if (current == null) return _unavailableFleetDetailsDialog(context);
          return FleetDetailsDialog(
            assetId: current.id,
            plateNumber: current.plateNumber,
            status: current.status,
            isActive: current.isActive,
            licenseExpiryDate: current.licenseExpiryDate,
            notes: current.technicalNotes,
            notesLabel: context.l10n.technicalNotesLabel,
            state: state is FleetLoaded ? state : null,
            onAssetChanged: () =>
                _refreshTrailerDetails(fleetCubit, current.id),
          );
        },
      ),
    ),
  );
  fleetCubit.clearFleetAssetActivity();
}

Future<void> _refreshTractorHeadDetails(
  FleetCubit cubit,
  String assetId,
) async {
  await cubit.refreshAssets();
  final state = cubit.state;
  if (state is! FleetLoaded) return;
  for (final item in state.allTractorHeads) {
    if (item.id == assetId) {
      await cubit.loadTractorHeadActivity(item);
      return;
    }
  }
}

Future<void> _refreshTrailerDetails(FleetCubit cubit, String assetId) async {
  await cubit.refreshAssets();
  final state = cubit.state;
  if (state is! FleetLoaded) return;
  for (final item in state.allTrailers) {
    if (item.id == assetId) {
      await cubit.loadTrailerActivity(item);
      return;
    }
  }
}

/// Never render a stale captured asset when RLS removes or changes it.
Widget _unavailableFleetDetailsDialog(BuildContext context) => Dialog(
  child: IconButton(
    onPressed: () => Navigator.of(context).pop(),
    icon: const Icon(AppIcons.clear),
    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
  ),
);

TractorHead? _tractorHeadFromState(FleetState state, String assetId) {
  if (state is! FleetLoaded) return null;
  for (final item in state.allTractorHeads) {
    if (item.id == assetId) return item;
  }
  return null;
}

TrailerEntity? _trailerFromState(FleetState state, String assetId) {
  if (state is! FleetLoaded) return null;
  for (final item in state.allTrailers) {
    if (item.id == assetId) return item;
  }
  return null;
}
