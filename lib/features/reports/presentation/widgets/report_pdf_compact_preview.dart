import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../localization/reports_localizations.dart';
import 'report_pdf_page_viewer.dart';

/// Full-screen PDF preview on narrow screens. PDF delivery remains separate.
final class ReportPdfCompactPreview extends StatelessWidget {
  final Uint8List bytes;

  const ReportPdfCompactPreview({required this.bytes, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.exportPdfPreviewTitle),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(AppIcons.clear),
          ),
        ],
      ),
      body: PdfPreviewCustom(
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
    );
  }
}
