import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/trip_entity.dart';
import '../localization/trips_localizations_x.dart';

class TripStatusChip extends StatelessWidget {
  final TripEntity trip;

  const TripStatusChip({required this.trip, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Chip(
      label: Text(l10n.tripStatusLabel(trip.status)),
      visualDensity: VisualDensity.compact,
    );
  }
}
