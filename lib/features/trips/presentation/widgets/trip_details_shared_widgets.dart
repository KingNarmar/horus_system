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
  static const double _stackedBreakpoint = 300;

  final String label;
  final String value;

  const TripDetailRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _stackedBreakpoint) {
          return _StackedDetailRow(label: label, value: value);
        }

        return _InlineDetailRow(label: label, value: value);
      },
    );
  }
}

class _InlineDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _InlineDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 42,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: Text(
                label,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          Expanded(
            flex: 58,
            child: Text(value, textAlign: TextAlign.start, softWrap: true),
          ),
        ],
      ),
    );
  }
}

class _StackedDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _StackedDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
