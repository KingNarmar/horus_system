import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../cubit/fleet_cubit.dart';
import '../cubit/fleet_state.dart';
import '../localization/fleet_localizations_x.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<FleetCubit, FleetState>(
      builder: (context, state) {
        if (state is FleetInitial || state is FleetLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FleetFailure) {
          return Text(l10n.localizedErrorMessage(state.failure));
        }
        if (state is! FleetLoaded) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.fleetTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            Text('${l10n.tractorHeadsTab}: ${state.allTractorHeads.length}'),
            Text('${l10n.trailersTab}: ${state.allTrailers.length}'),
          ],
        );
      },
    );
  }
}
