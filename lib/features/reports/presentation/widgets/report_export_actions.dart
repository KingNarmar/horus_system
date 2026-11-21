import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/report_export_progress.dart';
import '../../../../core/constants/app_spacing.dart';
import '../cubit/report_export_state.dart';
import '../localization/reports_localizations.dart';

final class ReportExportActions extends StatelessWidget {
  final ReportExportBusy? busy;
  final ValueChanged<ReportPdfAction> onAction;
  final VoidCallback onCancel;

  const ReportExportActions({
    required this.busy,
    required this.onAction,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;
    final progress = busy?.progress;
    final isBusy = busy != null;
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
          Text(
            progress?.stage == ReportExportStage.readingSource
                ? strings.loading
                : strings.exportPdfBusy,
          ),
          if (progress != null && progress.hasMeasuredRows)
            SizedBox(
              width: AppSizes.minButtonWidth,
              child: LinearProgressIndicator(
                value: progress.totalRows == 0
                    ? 1
                    : progress.loadedRows! / progress.totalRows!,
              ),
            ),
          if (progress?.stage != ReportExportStage.delivering)
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(AppIcons.clear),
              label: Text(strings.cancel),
            ),
        ],
      ],
    );
  }
}
