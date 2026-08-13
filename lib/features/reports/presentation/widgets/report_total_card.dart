import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

final class ReportTotalCard extends StatelessWidget {
  final String label;
  final String value;

  const ReportTotalCard({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
