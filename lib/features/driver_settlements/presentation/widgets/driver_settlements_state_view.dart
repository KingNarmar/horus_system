import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../cubit/driver_settlements_state.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';
import 'driver_settlements_filters.dart';
import 'driver_settlements_list.dart';

class DriverSettlementsStateView extends StatelessWidget {
  final DriverSettlementsState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDriverFilterChanged;
  final ValueChanged<DriverSettlementStatus?> onStatusFilterChanged;
  final ValueChanged<bool> onIncludeVoidedChanged;
  final ValueChanged<DriverSettlement> onViewDetails;

  const DriverSettlementsStateView({
    required this.state,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onDriverFilterChanged,
    required this.onStatusFilterChanged,
    required this.onIncludeVoidedChanged,
    required this.onViewDetails,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final currentState = state;

    if (currentState is DriverSettlementsInitial ||
        currentState is DriverSettlementsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentState is DriverSettlementsFailure) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Text(
                context.localizedDriverSettlementFailure(currentState.failure),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    if (currentState is! DriverSettlementsLoaded) {
      return const SizedBox.shrink();
    }

    final settlements = currentState.settlements;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DriverSettlementsFilters(
          drivers: currentState.driverOptions,
          selectedDriverId: currentState.driverIdFilter,
          selectedStatus: currentState.statusFilter,
          includeVoided: currentState.includeVoided,
          onSearchChanged: onSearchChanged,
          onDriverChanged: onDriverFilterChanged,
          onStatusChanged: onStatusFilterChanged,
          onIncludeVoidedChanged: onIncludeVoidedChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        if (currentState.allSettlements.isEmpty)
          _EmptyState(message: strings.noSettlements)
        else if (settlements.isEmpty)
          _EmptyState(message: strings.noMatchingSettlements)
        else
          DriverSettlementsList(
            state: currentState,
            settlements: settlements,
            onViewDetails: onViewDetails,
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
