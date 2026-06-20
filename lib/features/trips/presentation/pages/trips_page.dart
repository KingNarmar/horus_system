import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../localization/trips_localizations_x.dart';
import '../widgets/trip_details_dialog.dart';
import '../widgets/trip_status_update_dialog.dart';
import '../widgets/trips_filters.dart';
import '../widgets/trips_list.dart';

class TripsPage extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;

  const TripsPage({required this.currentCompanyContext, super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TripsCubit>().loadTrips(widget.currentCompanyContext);
  }

  Future<void> _openTripDetails(TripEntity trip) async {
    final cubit = context.read<TripsCubit>();

    cubit.loadTripDetails(trip);

    await showDialog<void>(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<TripsCubit, TripsState>(
            builder: (context, state) {
              return TripDetailsDialog(
                trip: trip,
                state: state is TripsLoaded ? state : null,
              );
            },
          ),
        );
      },
    );

    cubit.clearTripDetails();
  }

  Future<void> _showStatusUpdateDialog(TripEntity trip) {
    final cubit = context.read<TripsCubit>();

    return showDialog<void>(
      context: context,
      builder: (_) {
        return TripStatusUpdateDialog(
          trip: trip,
          onSubmit: (status, notes) {
            return cubit.updateTripStatus(
              trip: trip,
              newStatus: status,
              notes: notes,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<TripsCubit, TripsState>(
      listener: (context, state) {
        if (state is TripsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.localizedErrorMessage(state.failure))),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TripsHeader(title: l10n.tripsTitle),
            const SizedBox(height: AppSpacing.lg),
            if (state is TripsInitial || state is TripsLoading)
              const Center(child: CircularProgressIndicator())
            else if (state is TripsLoaded)
              _TripsLoadedBody(
                state: state,
                onViewDetails: _openTripDetails,
                onUpdateStatus: _showStatusUpdateDialog,
              )
            else if (state is TripsFailure)
              _TripsFailureView(
                failureText: l10n.localizedErrorMessage(state.failure),
                onRetry: () {
                  context.read<TripsCubit>().loadTrips(
                    widget.currentCompanyContext,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _TripsHeader extends StatelessWidget {
  final String title;

  const _TripsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _TripsLoadedBody extends StatelessWidget {
  final TripsLoaded state;
  final ValueChanged<TripEntity> onViewDetails;
  final ValueChanged<TripEntity> onUpdateStatus;

  const _TripsLoadedBody({
    required this.state,
    required this.onViewDetails,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsCubit>();
    final l10n = context.l10n;
    final trips = state.trips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripsFilters(
          statusFilter: state.statusFilter,
          onSearchChanged: cubit.setSearchQuery,
          onStatusFilterChanged: cubit.setStatusFilter,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.allTrips.isEmpty)
          _EmptyTripsCard(text: l10n.noTripsFound)
        else if (trips.isEmpty)
          _EmptyTripsCard(text: l10n.noTripsMatchFilters)
        else
          TripsList(
            trips: trips,
            canUpdateTripStatus: state.canUpdateTripStatus,
            canViewTripFinancials: state.canViewTripFinancials,
            isStatusChanging: state.isStatusChanging,
            onViewDetails: onViewDetails,
            onUpdateStatus: onUpdateStatus,
          ),
      ],
    );
  }
}

class _EmptyTripsCard extends StatelessWidget {
  final String text;

  const _EmptyTripsCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(text),
      ),
    );
  }
}

class _TripsFailureView extends StatelessWidget {
  final String failureText;
  final VoidCallback onRetry;

  const _TripsFailureView({required this.failureText, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(failureText),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: Text(l10n.tripRetryButton)),
          ],
        ),
      ),
    );
  }
}
