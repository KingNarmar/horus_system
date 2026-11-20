import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/report_pdf_page_layout.dart';
import '../localization/reports_localizations.dart';
import 'report_pdf_page_viewer.dart';

/// Full-screen preview retains the tested touch and button zoom behavior.
final class ReportPdfCompactPreview extends StatelessWidget {
  final Uint8List bytes;
  final ReportPdfPageLayout? pageLayout;
  final VoidCallback? onConfirmPrint;

  const ReportPdfCompactPreview({
    required this.bytes,
    this.pageLayout,
    this.onConfirmPrint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          onConfirmPrint == null
              ? strings.exportPdfPreviewTitle
              : strings.exportPdfPrintPreviewTitle,
        ),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(AppIcons.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreviewCustom(
              build: (_) async => bytes,
              dpi: AppSizes.reportPdfPreviewMobileDpi,
              pagesBuilder: (_, pages) => ReportPdfPageViewer(pages: pages),
              onError: (_, _) => Center(
                child: Text(
                  strings.exportPdfRenderFailure,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (onConfirmPrint != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pageLayout != null)
                      Text(switch (pageLayout!) {
                        ReportPdfPageLayout.a4Portrait =>
                          strings.exportPdfPaperA4Portrait,
                        ReportPdfPageLayout.a4Landscape =>
                          strings.exportPdfPaperA4Landscape,
                      }, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            MaterialLocalizations.of(context).cancelButtonLabel,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: onConfirmPrint,
                          icon: const Icon(AppIcons.print),
                          label: Text(strings.exportPdfPrint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
