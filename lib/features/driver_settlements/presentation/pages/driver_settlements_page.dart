import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver_settlement.dart';
import '../cubit/driver_settlements_cubit.dart';
import '../cubit/driver_settlements_state.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';
import '../widgets/driver_settlement_details_dialog.dart';
import '../widgets/driver_settlement_form_dialog.dart';
import '../widgets/driver_settlement_void_dialog.dart';
import '../widgets/driver_settlements_state_view.dart';

class DriverSettlementsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const DriverSettlementsPage({required this.currentCompanyContext, super.key});

  @override
  State<DriverSettlementsPage> createState() => _DriverSettlementsPageState();
}

class _DriverSettlementsPageState extends State<DriverSettlementsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DriverSettlementsCubit>().loadDriverSettlements(
      widget.currentCompanyContext,
    );
  }

  Future<void> _openCreateDraft() async {
    final cubit = context.read<DriverSettlementsCubit>();
    final state = cubit.state;
    if (state is! DriverSettlementsLoaded) return;

    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: DriverSettlementFormDialog(
          driverOptions: state.activeDriverOptions,
        ),
      ),
    );
  }

  Future<void> _openDetails(DriverSettlement settlement) async {
    final cubit = context.read<DriverSettlementsCubit>();
    final detailsFuture = cubit.loadSettlementDetails(settlement);
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<DriverSettlementsCubit, DriverSettlementsState>(
          builder: (context, state) {
            if (state is! DriverSettlementsLoaded) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }
            return DriverSettlementDetailsDialog(
              state: state,
              onRetry: () {
                final selected = state.selectedSettlement;
                if (selected != null) {
                  cubit.loadSettlementDetails(selected);
                }
              },
              onFinalize: _confirmFinalize,
              onVoid: _confirmVoid,
            );
          },
        ),
      ),
    );
    await detailsFuture;
    cubit.clearSettlementDetails();
  }

  Future<void> _confirmFinalize(DriverSettlement settlement) async {
    final strings = context.driverSettlementsL10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.finalizeTitle),
        content: Text(strings.finalizeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.finalize),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<DriverSettlementsCubit>().finalizeSettlement(settlement);
  }

  Future<void> _confirmVoid(DriverSettlement settlement) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const DriverSettlementVoidDialog(),
    );
    if (reason == null || !mounted) return;
    await context.read<DriverSettlementsCubit>().voidSettlement(
      settlement,
      reason: reason,
    );
  }

  void _showFeedback(BuildContext context, DriverSettlementsLoaded state) {
    final strings = context.driverSettlementsL10n;
    final message = switch (state.feedback) {
      DriverSettlementFeedback.draftCreated => strings.draftCreated,
      DriverSettlementFeedback.finalized => strings.settlementFinalized,
      DriverSettlementFeedback.voided => strings.settlementVoided,
      null =>
        state.mutationFailure == null
            ? null
            : context.localizedDriverSettlementFailure(state.mutationFailure!),
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    context.read<DriverSettlementsCubit>().clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    return BlocConsumer<DriverSettlementsCubit, DriverSettlementsState>(
      listenWhen: (previous, current) {
        if (current is! DriverSettlementsLoaded) return false;
        if (previous is! DriverSettlementsLoaded) {
          return current.feedback != null || current.mutationFailure != null;
        }
        return previous.feedback != current.feedback ||
            previous.mutationFailure != current.mutationFailure;
      },
      listener: (context, state) {
        if (state is DriverSettlementsLoaded) _showFeedback(context, state);
      },
      builder: (context, state) {
        final cubit = context.read<DriverSettlementsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (state is DriverSettlementsLoaded &&
                    state.canManageDriverSettlements)
                  FilledButton.icon(
                    onPressed: state.activeDriverOptions.isEmpty
                        ? null
                        : _openCreateDraft,
                    icon: const Icon(AppIcons.add),
                    label: Text(strings.addDraft),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DriverSettlementsStateView(
              state: state,
              onRetry: () =>
                  cubit.loadDriverSettlements(widget.currentCompanyContext),
              onSearchChanged: cubit.setSearchQuery,
              onDriverFilterChanged: cubit.setDriverFilter,
              onStatusFilterChanged: cubit.setStatusFilter,
              onIncludeVoidedChanged: cubit.setIncludeVoided,
              onViewDetails: _openDetails,
            ),
          ],
        );
      },
    );
  }
}
