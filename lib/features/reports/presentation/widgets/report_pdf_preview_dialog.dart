import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/report_pdf_page_layout.dart';
import '../localization/reports_localizations.dart';
import 'report_pdf_compact_preview.dart';

/// Read-only PDF preview. A print request requires explicit confirmation.
final class ReportPdfPreviewDialog extends StatelessWidget {
  final Uint8List bytes;
  final ReportPdfPageLayout? pageLayout;
  final VoidCallback? onConfirmPrint;

  const ReportPdfPreviewDialog({
    required this.bytes,
    this.pageLayout,
    this.onConfirmPrint,
    super.key,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < AppSizes.desktopMinWidth) {
        return ReportPdfCompactPreview(
          bytes: bytes,
          pageLayout: pageLayout,
          onConfirmPrint: onConfirmPrint,
        );
      }
      return _buildDesktop(context);
    },
  );

  Widget _buildDesktop(BuildContext context) {
    final strings = context.reportsL10n;
    final layout = pageLayout;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.reportPdfPreviewMaxWidth,
          maxHeight: AppSizes.reportPdfPreviewMaxHeight,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          onConfirmPrint == null
                              ? strings.exportPdfPreviewTitle
                              : strings.exportPdfPrintPreviewTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (layout != null)
                          Text(reportPdfPaperLabel(strings, layout)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.clear),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) async => bytes,
                onError: (context, error) => Center(
                  child: Text(
                    strings.exportPdfRenderFailure,
                    textAlign: TextAlign.center,
                  ),
                ),
                allowPrinting: false,
                allowSharing: false,
                canChangeOrientation: false,
                canChangePageFormat: false,
              ),
            ),
            if (onConfirmPrint != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: onConfirmPrint,
                      icon: const Icon(AppIcons.print),
                      label: Text(strings.exportPdfPrint),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String reportPdfPaperLabel(
  ReportsLocalizations strings,
  ReportPdfPageLayout pageLayout,
) => switch (pageLayout) {
  ReportPdfPageLayout.a4Portrait => strings.exportPdfPaperA4Portrait,
  ReportPdfPageLayout.a4Landscape => strings.exportPdfPaperA4Landscape,
};

