part of 'fleet_asset_cards.dart';

class _TractorHeadsTable extends StatelessWidget {
  final TractorHeadCards view;
  const _TractorHeadsTable({required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TableShell(
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.plateNumberLabel)),
          DataColumn(label: Text(l10n.vehicleStatusLabel)),
          DataColumn(label: Text(l10n.vehicleLicenseExpiryDateLabel)),
          DataColumn(label: Text(l10n.expectedFuelConsumptionLabel)),
          DataColumn(label: Text(l10n.vehicleNotesLabel)),
          DataColumn(label: Text(l10n.statusHeader)),
          DataColumn(label: Text(l10n.actionsHeader)),
        ],
        rows: view.tractorHeads.map((item) {
          final loading = view.isActionLoading(item.id);
          return DataRow(
            cells: [
              DataCell(Text(item.plateNumber)),
              DataCell(Text(l10n.vehicleStatusText(item.status))),
              DataCell(Text(_dateOnlyOrEmpty(context, item.licenseExpiryDate))),
              DataCell(
                Text(
                  item.expectedFuelConsumption == null
                      ? l10n.emptyValue
                      : _numberText(item.expectedFuelConsumption!),
                ),
              ),
              DataCell(Text(item.notes ?? l10n.emptyValue)),
              DataCell(
                Text(item.isActive ? l10n.activeStatus : l10n.inactiveStatus),
              ),
              DataCell(
                _Actions(
                  canManage: view.canManageFleet,
                  isActive: item.isActive,
                  isLoading: loading,
                  onViewDetails: () => _openTractorHeadDetails(context, item),
                  onEdit: () => view.onEdit(item),
                  onDeactivate: () => view.onDeactivate(item),
                  onReactivate: () => view.onReactivate(item),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TrailersTable extends StatelessWidget {
  final TrailerCards view;
  const _TrailersTable({required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _TableShell(
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.plateNumberLabel)),
          DataColumn(label: Text(l10n.vehicleStatusLabel)),
          DataColumn(label: Text(l10n.vehicleLicenseExpiryDateLabel)),
          DataColumn(label: Text(l10n.technicalNotesLabel)),
          DataColumn(label: Text(l10n.statusHeader)),
          DataColumn(label: Text(l10n.actionsHeader)),
        ],
        rows: view.trailers.map((item) {
          final loading = view.isActionLoading(item.id);
          return DataRow(
            cells: [
              DataCell(Text(item.plateNumber)),
              DataCell(Text(l10n.vehicleStatusText(item.status))),
              DataCell(Text(_dateOnlyOrEmpty(context, item.licenseExpiryDate))),
              DataCell(Text(item.technicalNotes ?? l10n.emptyValue)),
              DataCell(
                Text(item.isActive ? l10n.activeStatus : l10n.inactiveStatus),
              ),
              DataCell(
                _Actions(
                  canManage: view.canManageFleet,
                  isActive: item.isActive,
                  isLoading: loading,
                  onViewDetails: () => _openTrailerDetails(context, item),
                  onEdit: () => view.onEdit(item),
                  onDeactivate: () => view.onDeactivate(item),
                  onReactivate: () => view.onReactivate(item),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TableShell extends StatelessWidget {
  final DataTable child;
  const _TableShell({required this.child});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minWidth = constraints.maxWidth > AppSizes.desktopMinWidth
          ? constraints.maxWidth
          : AppSizes.desktopMinWidth;
      return Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: child,
          ),
        ),
      );
    },
  );
}
