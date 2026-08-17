part of 'fleet_asset_cards.dart';

Future<void> _openTractorHeadDetails(
  BuildContext context,
  TractorHead item,
) async {
  final cubit = context.read<FleetCubit>();
  cubit.loadTractorHeadActivity(item);
  await showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<FleetCubit, FleetState>(
        builder: (context, state) => FleetDetailsDialog(
          assetId: item.id,
          plateNumber: item.plateNumber,
          status: item.status,
          isActive: item.isActive,
          licenseExpiryDate: item.licenseExpiryDate,
          expectedFuelConsumption: item.expectedFuelConsumption,
          notes: item.notes,
          notesLabel: context.l10n.vehicleNotesLabel,
          state: state is FleetLoaded ? state : null,
        ),
      ),
    ),
  );
  cubit.clearFleetAssetActivity();
}

Future<void> _openTrailerDetails(
  BuildContext context,
  TrailerEntity item,
) async {
  final cubit = context.read<FleetCubit>();
  cubit.loadTrailerActivity(item);
  await showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<FleetCubit, FleetState>(
        builder: (context, state) => FleetDetailsDialog(
          assetId: item.id,
          plateNumber: item.plateNumber,
          status: item.status,
          isActive: item.isActive,
          licenseExpiryDate: item.licenseExpiryDate,
          notes: item.technicalNotes,
          notesLabel: context.l10n.technicalNotesLabel,
          state: state is FleetLoaded ? state : null,
        ),
      ),
    ),
  );
  cubit.clearFleetAssetActivity();
}
