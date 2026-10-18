import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trip_freight_rate_cubit.dart';
import '../helpers/trips_failure_message.dart';

final class TripFreightRateDialog extends StatefulWidget {
  final CurrentCompanyContext currentCompanyContext;
  final TripEntity trip;

  const TripFreightRateDialog({
    required this.currentCompanyContext,
    required this.trip,
    super.key,
  });

  @override
  State<TripFreightRateDialog> createState() => _TripFreightRateDialogState();
}

final class _TripFreightRateDialogState extends State<TripFreightRateDialog> {
  final TextEditingController _rateController = TextEditingController();

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<TripFreightRateCubit, TripFreightRateState>(
      listener: (context, state) {
        if (state is TripFreightRateSaved) {
          Navigator.of(context).pop(state.trip);
        }
      },
      builder: (context, state) {
        final isSaving = state is TripFreightRateSaving;
        return AlertDialog(
          title: Text(l10n.tripEditFreightRateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.trip.displayName),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _rateController,
                enabled: !isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.tripAgreedFreightRatePerTonLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (state is TripFreightRateFailure) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  tripsFailureMessage(context, state.failure),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.tripCancelRateButton),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () => context.read<TripFreightRateCubit>().save(
                      companyContext: widget.currentCompanyContext,
                      trip: widget.trip,
                      agreedFreightRatePerTonInput: _rateController.text,
                    ),
              child: Text(l10n.tripSaveRateButton),
            ),
          ],
        );
      },
    );
  }
}
