import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/localization/financial_readiness_localizations.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement_type.dart';
import '../../../driver_finance/presentation/widgets/driver_financial_movement_form_dialog.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../../domain/entities/driver_status_filter.dart';
import '../../domain/policies/driver_compensation_permission_policy.dart';
import '../cubit/driver_compensation_cubit.dart';
import '../cubit/driver_compensation_state.dart';
import '../cubit/drivers_cubit.dart';
import '../cubit/drivers_state.dart';
import '../helpers/driver_contract_document_launcher.dart';
import '../helpers/driver_contract_file_picker.dart';
import '../localization/driver_compensation_localizations.dart';
import '../widgets/driver_compensation_end_dialog.dart';
import '../widgets/driver_compensation_form_dialog.dart';
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
  static const DriverContractFilePicker _contractFilePicker =
      DriverContractFilePicker();
  static const DriverContractDocumentLauncher _contractDocumentLauncher =
      DriverContractDocumentLauncher();

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
              imageUploads: data.imageUploads,
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
            imageUploads: data.imageUploads,
            notes: data.notes,
          );
        },
      ),
    );
  }

  Future<void> _openDetails(Driver driver) async {
    final driversCubit = context.read<DriversCubit>();
    final compensationCubit = context.read<DriverCompensationCubit>();
    final canViewCompensation = DriverCompensationPermissionPolicy.canView(
      widget.currentCompanyContext.role,
    );

    driversCubit.loadDriverImageUrls(driver);
    driversCubit.loadDriverActivity(driver);
    driversCubit.loadDriverFinancialMovements(driver);
    driversCubit.loadDriverTripOptions(driver);

    if (canViewCompensation) {
      await compensationCubit.loadForDriver(
        currentCompanyContext: widget.currentCompanyContext,
        driverId: driver.id,
      );
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => BlocBuilder<DriversCubit, DriversState>(
        builder: (context, state) => DriverDetailsDialog(
          driver: driver,
          state: state is DriversLoaded ? state : null,
          showCompensation: canViewCompensation,
          onAddCompensationRevision: canViewCompensation
              ? () => _openCompensationForm(driver)
              : null,
          onEndCompensationRevision: canViewCompensation
              ? (revision) => _openCompensationEndDialog(driver, revision)
              : null,
          onAttachCompensationContract: canViewCompensation
              ? (revision) => _attachCompensationContract(driver, revision)
              : null,
          onOpenCompensationContract: canViewCompensation
              ? _openCompensationContract
              : null,
          onAddAdvance: () => _openFinancialMovementForm(
            driver: driver,
            movementType: DriverFinancialMovementType.advance,
          ),
          onAddDriverCharge: () => _openFinancialMovementForm(
            driver: driver,
            movementType: DriverFinancialMovementType.driverCharge,
          ),
          onAddCashReturn: () => _openFinancialMovementForm(
            driver: driver,
            movementType: DriverFinancialMovementType.cashReturn,
          ),
        ),
      ),
    );
    driversCubit.clearDriverActivity();
    if (canViewCompensation) compensationCubit.clear();
  }

  Future<void> _openCompensationForm(Driver driver) async {
    final compensationCubit = context.read<DriverCompensationCubit>();
    final compensationState = compensationCubit.state;
    if (compensationState is! DriverCompensationLoaded) return;

    final configuration = CurrencyConfiguration.tryCreate(
      currencyCode: widget.currentCompanyContext.company.baseCurrencyCode,
      fractionDigits:
          widget.currentCompanyContext.company.baseCurrencyFractionDigits,
    );
    if (configuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.financialReadinessL10n.configurationRequired,
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => DriverCompensationFormDialog(
        financialConfiguration: configuration,
        initialEffectiveFrom: compensationState.businessDate,
        onSubmit:
            ({
              required Money amount,
              required BusinessDate effectiveFrom,
              BusinessDate? effectiveTo,
              String? contractReference,
              BusinessDocumentFile? contractDocument,
            }) async {
              final failure = await compensationCubit.createRevision(
                amount: amount,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                contractReference: contractReference,
                contractDocument: contractDocument,
              );
              if (failure == null && mounted) {
                await context.read<DriversCubit>().loadDriverActivity(driver);
              }
              return failure;
            },
      ),
    );
  }

  Future<void> _openCompensationEndDialog(
    Driver driver,
    DriverCompensationRevision revision,
  ) async {
    final compensationCubit = context.read<DriverCompensationCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => DriverCompensationEndDialog(
        revision: revision,
        initialEffectiveTo: revision.effectiveFrom,
        onSubmit: (effectiveTo) async {
          final failure = await compensationCubit.endRevision(
            revision: revision,
            effectiveTo: effectiveTo,
          );
          if (failure == null && mounted) {
            await context.read<DriversCubit>().loadDriverActivity(driver);
          }
          return failure;
        },
      ),
    );
  }

  Future<void> _attachCompensationContract(
    Driver driver,
    DriverCompensationRevision revision,
  ) async {
    final l10n = context.driverCompensationL10n;
    try {
      final document = await _contractFilePicker.pick();
      if (document == null || !mounted) return;

      final failure = await context
          .read<DriverCompensationCubit>()
          .attachContractDocument(revision: revision, document: document);
      if (!mounted) return;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(driverCompensationFailureMessage(context, failure)),
          ),
        );
        return;
      }
      await context.read<DriversCubit>().loadDriverActivity(driver);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.filePickerFailed)),
      );
    }
  }

  Future<void> _openCompensationContract(
    DriverCompensationRevision revision,
  ) async {
    final l10n = context.driverCompensationL10n;
    final result = await context
        .read<DriverCompensationCubit>()
        .createContractAccess(revision);
    if (!mounted) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(driverCompensationFailureMessage(context, failure)),
        ),
      );
      return;
    }

    final access = result.dataOrNull;
    if (access == null || !await _contractDocumentLauncher.open(access.value)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.openDocumentFailed)),
      );
    }
  }

  Future<void> _openFinancialMovementForm({
    required Driver driver,
    required DriverFinancialMovementType movementType,
  }) async {
    final cubit = context.read<DriversCubit>();
    final initialMovementDate = await cubit
        .getCurrentDriverFinanceBusinessDate();
    if (!mounted || initialMovementDate == null) return;

    await showDialog<void>(
      context: context,
      builder: (_) => BlocBuilder<DriversCubit, DriversState>(
        builder: (context, state) {
          final loaded = state is DriversLoaded ? state : null;
          return DriverFinancialMovementFormDialog(
            movementType: movementType,
            initialMovementDate: initialMovementDate,
            tripOptions: loaded?.selectedDriverTripOptions ?? const [],
            isTripOptionsLoading: loaded?.isTripOptionsLoading ?? false,
            tripOptionsFailure: loaded?.tripOptionsFailure,
            onSubmit:
                ({
                  required double amount,
                  required BusinessDate movementDate,
                  String? tripId,
                  String? notes,
                }) async {
                  final cubit = context.read<DriversCubit>();
                  switch (movementType) {
                    case DriverFinancialMovementType.advance:
                      await cubit.addDriverAdvance(
                        driver: driver,
                        amount: amount,
                        movementDate: movementDate,
                        notes: notes,
                      );
                      break;
                    case DriverFinancialMovementType.driverCharge:
                      await cubit.addDriverCharge(
                        driver: driver,
                        amount: amount,
                        movementDate: movementDate,
                        tripId: tripId,
                        notes: notes,
                      );
                      break;
                    case DriverFinancialMovementType.cashReturn:
                      await cubit.addDriverCashReturn(
                        driver: driver,
                        amount: amount,
                        movementDate: movementDate,
                        notes: notes,
                      );
                      break;
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
                Expanded(
                  child: Text(
                    l10n.driversTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (state is DriversLoaded && state.canManageDrivers)
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.addDriverButton),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state is DriversInitial || state is DriversLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is DriversFailure)
              _MessageCard(
                message: l10n.localizedErrorMessage(state.failure),
                action: OutlinedButton(
                  onPressed: () =>
                      cubit.loadDrivers(widget.currentCompanyContext),
                  child: Text(l10n.retryButton),
                ),
              )
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

  const _Filters({
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.searchFieldMaxWidth,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(AppIcons.search),
              hintText: l10n.searchDriversHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SegmentedButton<DriverStatusFilter>(
          segments: [
            ButtonSegment(
              value: DriverStatusFilter.all,
              label: Text(l10n.driversStatusAllFilter),
            ),
            ButtonSegment(
              value: DriverStatusFilter.active,
              label: Text(l10n.driversStatusActiveFilter),
            ),
            ButtonSegment(
              value: DriverStatusFilter.inactive,
              label: Text(l10n.driversStatusInactiveFilter),
            ),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selected) =>
              onStatusFilterChanged(selected.first),
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
