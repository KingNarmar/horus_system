import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_spacing.dart';

class AdaptiveDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const AdaptiveDetailRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelStyle =
        labelStyle ?? const TextStyle(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AppSizes.detailsStackBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: effectiveLabelStyle),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: valueStyle),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppSizes.detailsLabelWidth,
                child: Text(label, style: effectiveLabelStyle),
              ),
              Expanded(child: Text(value, style: valueStyle)),
            ],
          );
        },
      ),
    );
  }
}
