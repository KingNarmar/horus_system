import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/reports_localizations.dart';
import 'report_pdf_compact_preview.dart';

/// Read-only PDF preview; save/share/print regenerate from current authority.
final class ReportPdfPreviewDialog extends StatelessWidget {
  final Uint8List bytes;

  const ReportPdfPreviewDialog({required this.bytes, super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < AppSizes.desktopMinWidth) {
      return ReportPdfCompactPreview(bytes: bytes);
    }

    final strings = context.reportsL10n;
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
                    child: Text(
                      strings.exportPdfPreviewTitle,
                      style: Theme.of(context).textTheme.titleLarge,
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
          ],
        ),
      ),
    );
  }
}
