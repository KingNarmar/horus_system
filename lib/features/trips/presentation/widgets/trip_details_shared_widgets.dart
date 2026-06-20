import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_extension.dart';

class TripDetailsCard extends StatelessWidget {
  final List<Widget> children;

  const TripDetailsCard({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class TripDetailRow extends StatelessWidget {
  static const double _compactBreakpoint = 440;

  final String label;
  final String value;

  const TripDetailRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < _compactBreakpoint;

        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(value),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.34,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(value)),
            ],
          ),
        );
      },
    );
  }
}

class TripDetailsSectionTitle extends StatelessWidget {
  final String text;

  const TripDetailsSectionTitle({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class TripDetailsFailureCard extends StatelessWidget {
  final Failure failure;

  const TripDetailsFailureCard({required this.failure, super.key});

  @override
  Widget build(BuildContext context) {
    return TripDetailsCard(
      children: [Text(context.l10n.localizedErrorMessage(failure))],
    );
  }
}
