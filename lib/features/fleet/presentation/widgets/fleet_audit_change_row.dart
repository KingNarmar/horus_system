import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../audit/presentation/helpers/audit_change_builder.dart';

/// Keeps long audit values readable without mixing Latin paths with RTL labels.
final class FleetAuditChangeRow extends StatelessWidget {
  final AuditChange change;

  const FleetAuditChangeRow({required this.change, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            change.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          _AuditValue(
            label: l10n.fleetAuditPreviousValueLabel,
            value: change.oldValue,
          ),
          const SizedBox(height: AppSpacing.xs),
          _AuditValue(
            label: l10n.fleetAuditNewValueLabel,
            value: change.newValue,
          ),
        ],
      ),
    );
  }
}

final class _AuditValue extends StatelessWidget {
  final String label;
  final String value;

  const _AuditValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          textDirection: Bidi.detectRtlDirectionality(value)
              ? TextDirection.rtl
              : TextDirection.ltr,
          softWrap: true,
        ),
      ],
    );
  }
}
