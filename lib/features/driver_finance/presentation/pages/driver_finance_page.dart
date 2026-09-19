import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver_financial_movement_type.dart';
import '../cubit/driver_finance_cubit.dart';
import '../cubit/driver_finance_state.dart';
import '../widgets/driver_finance_details_section.dart';
import '../widgets/driver_financial_movement_form_dialog.dart';

final class DriverFinancePage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const DriverFinancePage({required this.currentCompanyContext, super.key});

  @override
  State<DriverFinancePage> createState() => _DriverFinancePageState();
}

final class _DriverFinancePageState extends State<DriverFinancePage> {
  @override
  void initState() {
    super.initState();
    context.read<DriverFinanceCubit>().load(widget.currentCompanyContext);
  }

  @override
  void didUpdateWidget(covariant DriverFinancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCompanyContext.companyId !=
            widget.currentCompanyContext.companyId ||
        oldWidget.currentCompanyContext.role !=
            widget.currentCompanyContext.role) {
      context.read<DriverFinanceCubit>().load(widget.currentCompanyContext);
    }
  }

  Future<void> _openMovementForm(
    DriverFinancialMovementType movementType,
  ) async {
    final cubit = context.read<DriverFinanceCubit>();
    final businessDateResult = await cubit.getCurrentBusinessDate();
    if (!mounted) return;

    if (businessDateResult is FailureResult<BusinessDate>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.localizedErrorMessage(businessDateResult.failure),
          ),
        ),
      );
      return;
    }

    final state = cubit.state;
    if (state is! DriverFinanceLoaded || state.selectedDriverId == null) return;

    await showDialog<void>(
      context: context,
      builder: (_) => DriverFinancialMovementFormDialog(
        movementType: movementType,
        initialMovementDate: (businessDateResult as Success<BusinessDate>).data,
        tripOptions: state.tripOptions,
        isTripOptionsLoading: state.isDetailsLoading,
        tripOptionsFailure: state.failure,
        onSubmit:
            ({
              required String amount,
              required BusinessDate movementDate,
              String? tripId,
              String? notes,
            }) async {
              switch (movementType) {
                case DriverFinancialMovementType.advance:
                  await cubit.addDriverAdvance(
                    amount: amount,
                    movementDate: movementDate,
                    notes: notes,
                  );
                  break;
                case DriverFinancialMovementType.driverCharge:
                  await cubit.addDriverCharge(
                    amount: amount,
                    movementDate: movementDate,
                    tripId: tripId,
                    notes: notes,
                  );
                  break;
                case DriverFinancialMovementType.cashReturn:
                  await cubit.addDriverCashReturn(
                    amount: amount,
                    movementDate: movementDate,
                    notes: notes,
                  );
                  break;
              }
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<DriverFinanceCubit, DriverFinanceState>(
      builder: (context, state) {
        final cubit = context.read<DriverFinanceCubit>();

        return switch (state) {
          DriverFinanceInitial() || DriverFinanceLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          DriverFinanceFailure(:final failure) => Column(
            children: [
              Text(l10n.localizedErrorMessage(failure)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => cubit.load(widget.currentCompanyContext),
                child: Text(l10n.retryButton),
              ),
            ],
          ),
          DriverFinanceLoaded() => _LoadedDriverFinance(
            state: state,
            onDriverChanged: cubit.selectDriver,
            onAddAdvance: () =>
                _openMovementForm(DriverFinancialMovementType.advance),
            onAddDriverCharge: () =>
                _openMovementForm(DriverFinancialMovementType.driverCharge),
            onAddCashReturn: () =>
                _openMovementForm(DriverFinancialMovementType.cashReturn),
          ),
        };
      },
    );
  }
}

final class _LoadedDriverFinance extends StatelessWidget {
  final DriverFinanceLoaded state;
  final ValueChanged<String?> onDriverChanged;
  final VoidCallback onAddAdvance;
  final VoidCallback onAddDriverCharge;
  final VoidCallback onAddCashReturn;

  const _LoadedDriverFinance({
    required this.state,
    required this.onDriverChanged,
    required this.onAddAdvance,
    required this.onAddDriverCharge,
    required this.onAddCashReturn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.drivers.isEmpty) {
      return Text(l10n.noDriversFound);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: state.selectedDriverId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.driverNameLabel,
            border: const OutlineInputBorder(),
          ),
          items: state.drivers
              .map(
                (driver) => DropdownMenuItem(
                  value: driver.id,
                  child: Text(driver.fullName, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: state.isSaving ? null : onDriverChanged,
        ),
        if (state.selectedDriverId != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DriverFinanceDetailsSection(
            movements: state.movements,
            balance: state.balance,
            tripOptions: state.tripOptions,
            canManage: state.canManage,
            isLoading: state.isDetailsLoading,
            isSaving: state.isSaving,
            failure: state.failure,
            onAddAdvance: onAddAdvance,
            onAddDriverCharge: onAddDriverCharge,
            onAddCashReturn: onAddCashReturn,
          ),
        ],
      ],
    );
  }
}
