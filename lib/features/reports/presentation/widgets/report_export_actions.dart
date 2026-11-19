import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../cubit/report_export_state.dart';
import '../localization/reports_localizations.dart';

final class ReportExportActions extends StatelessWidget {
  final bool isBusy;
  final ValueChanged<ReportPdfAction> onAction;

  const ReportExportActions({
    required this.isBusy,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => onAction(ReportPdfAction.preview),
          icon: const Icon(AppIcons.view),
          label: Text(strings.exportPdfPreview),
        ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => onAction(ReportPdfAction.save),
          icon: const Icon(AppIcons.download),
          label: Text(strings.exportPdfSave),
        ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => onAction(ReportPdfAction.print),
          icon: const Icon(AppIcons.print),
          label: Text(strings.exportPdfPrint),
        ),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => onAction(ReportPdfAction.share),
          icon: const Icon(AppIcons.share),
          label: Text(strings.exportPdfShare),
        ),
        if (isBusy) ...[
          const SizedBox(width: AppSpacing.sm),
          const SizedBox(
            width: AppSpacing.lg,
            height: AppSpacing.lg,
            child: CircularProgressIndicator(),
          ),
          Text(strings.exportPdfBusy),
        ],
      ],
    );
  }
}
