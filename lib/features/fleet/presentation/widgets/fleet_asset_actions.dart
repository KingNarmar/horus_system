part of 'fleet_asset_cards.dart';

class _Actions extends StatelessWidget {
  final bool canManage;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  const _Actions({
    required this.canManage,
    required this.isActive,
    required this.isLoading,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDeactivate,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.fleetDetailsButton,
          onPressed: onViewDetails,
          icon: const Icon(AppIcons.view),
        ),
        if (canManage) ...[
          IconButton(
            tooltip: l10n.editButton,
            onPressed: isLoading ? null : onEdit,
            icon: const Icon(AppIcons.edit),
          ),
          IconButton(
            tooltip: isActive
                ? l10n.fleetDeactivateButton
                : l10n.fleetReactivateButton,
            onPressed: isLoading
                ? null
                : (isActive ? onDeactivate : onReactivate),
            icon: _ActionIcon(
              isLoading: isLoading,
              icon: isActive ? AppIcons.deactivate : AppIcons.reactivate,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  const _ActionIcon({required this.isLoading, required this.icon});

  @override
  Widget build(BuildContext context) => isLoading
      ? const SizedBox(
          width: AppSizes.iconMd,
          height: AppSizes.iconMd,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
          ),
        )
      : Icon(icon);
}
