import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement_type.dart';
import '../../../driver_finance/presentation/widgets/driver_financial_movement_form_dialog.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status_filter.dart';
import '../cubit/drivers_cubit.dart';
import '../cubit/drivers_state.dart';
import '../localization/drivers_localizations_x.dart';
import '../widgets/driver_details_dialog.dart';
import '../widgets/driver_form_dialog.dart';
import '../widgets/drivers_cards.dart';
import '../widgets/drivers_table.dart';

class DriversPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const DriversPage({required this.currentCompanyContext, super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  @override
  void initState() {
    super.initState();
    context.read<DriversCubit>().loadDrivers(widget.currentCompanyContext);
  }

  Future<void> _openForm({Driver? driver}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DriverFormDialog(
        driver: driver,
        onSubmit: (data) {
          final cubit = context.read<DriversCubit>();
          if (driver == null) {
            return cubit.addDriver(
              fullName: data.fullName,
              phone: data.phone,
              nationalId: data.nationalId,
              licenseNumber: data.licenseNumber,
              licenseExpiryDate: data.licenseExpiryDate,
              notes: data.notes,
            );
          }
          return cubit.updateDriver(
            driver: driver,
            fullName: data.fullName,
            phone: data.phone,
            nationalId: data.nationalId,
            licenseNumber: data.licenseNumber,
            licenseExpiryDate: data.licenseExpiryDate,
            notes: data.notes,
          );
        },
      ),
    );
  }

  Future<void> _openDetails(Driver driver) async {
    final cubit = context.read<DriversCubit>();
    cubit.loadDriverActivity(driver);
    cubit.loadDriverFinancialMovements(driver);
    cubit.loadDriverTripOptions(driver);
    await showDialog<void>(
      context: context,
      builder: (_) => BlocBuilder<DriversCubit, DriversState>(
        builder: (context, state) => DriverDetailsDialog(
          driver: driver,
          state: state is DriversLoaded ? state : null,
          onAddAdvance: () => _openFinancialMovementForm(
            driver: driver,
            movementType: DriverFinancialMovementType.advance,
          ),
          onAddDeduction: () => _openFinancialMovementForm(
            driver: driver,
            movementType: DriverFinancialMovementType.deduction,
          ),
        ),
      ),
    );
    cubit.clearDriverActivity();
  }

  Future<void> _openFinancialMovementForm({
    required Driver driver,
    required DriverFinancialMovementType movementType,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BlocBuilder<DriversCubit, DriversState>(
        builder: (context, state) {
          final loaded = state is DriversLoaded ? state : null;
          return DriverFinancialMovementFormDialog(
            movementType: movementType,
            tripOptions: loaded?.selectedDriverTripOptions ?? const [],
            isTripOptionsLoading: loaded?.isTripOptionsLoading ?? false,
            tripOptionsFailure: loaded?.tripOptionsFailure,
            onSubmit: ({
              required double amount,
              required DateTime movementDate,
              String? tripId,
              String? notes,
            }) async {
              final cubit = context.read<DriversCubit>();
              if (movementType.isAdvance) {
                await cubit.addDriverAdvance(
                  driver: driver,
                  amount: amount,
                  movementDate: movementDate,
                  notes: notes,
                );
              } else {
                await cubit.addDriverDeduction(
                  driver: driver,
                  amount: amount,
                  movementDate: movementDate,
                  tripId: tripId,
                  notes: notes,
                );
              }
              await cubit.loadDriverActivity(driver);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<DriversCubit, DriversState>(
      builder: (context, state) {
        final cubit = context.read<DriversCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.driversTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                if (state is DriversLoaded && state.canManageDrivers)
                  FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(AppIcons.add), label: Text(l10n.addDriverButton)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state is DriversInitial || state is DriversLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is DriversFailure)
              _MessageCard(message: l10n.localizedErrorMessage(state.failure), action: OutlinedButton(onPressed: () => cubit.loadDrivers(widget.currentCompanyContext), child: Text(l10n.retryButton)))
            else if (state is DriversLoaded) ...[
              _Filters(
                statusFilter: state.statusFilter,
                onSearchChanged: cubit.setSearchQuery,
                onStatusFilterChanged: cubit.setStatusFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.allDrivers.isEmpty)
                _MessageCard(message: l10n.noDriversFound)
              else if (state.drivers.isEmpty)
                _MessageCard(message: l10n.noDriversMatchFilters)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= AppSizes.dataTableBreakpoint) {
                      return DriversTable(
                        drivers: state.drivers,
                        canManageDrivers: state.canManageDrivers,
                        onViewDetails: _openDetails,
                        onEdit: (driver) => _openForm(driver: driver),
                        onDeactivate: cubit.deactivateDriver,
                        onReactivate: cubit.reactivateDriver,
                      );
                    }
                    return DriversCards(
                      drivers: state.drivers,
                      canManageDrivers: state.canManageDrivers,
                      onViewDetails: _openDetails,
                      onEdit: (driver) => _openForm(driver: driver),
                      onDeactivate: cubit.deactivateDriver,
                      onReactivate: cubit.reactivateDriver,
                    );
                  },
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  final DriverStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DriverStatusFilter> onStatusFilterChanged;

  const _Filters({required this.statusFilter, required this.onSearchChanged, required this.onStatusFilterChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.searchFieldMaxWidth),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(prefixIcon: const Icon(AppIcons.search), hintText: l10n.searchDriversHint, border: const OutlineInputBorder()),
          ),
        ),
        SegmentedButton<DriverStatusFilter>(
          segments: [
            ButtonSegment(value: DriverStatusFilter.all, label: Text(l10n.driversStatusAllFilter)),
            ButtonSegment(value: DriverStatusFilter.active, label: Text(l10n.driversStatusActiveFilter)),
            ButtonSegment(value: DriverStatusFilter.inactive, label: Text(l10n.driversStatusInactiveFilter)),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) => onStatusFilterChanged(selected.first),
        ),
      ],
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
            if (action != null) ...[const SizedBox(height: AppSpacing.md), action!],
          ],
        ),
      ),
    );
  }
}
