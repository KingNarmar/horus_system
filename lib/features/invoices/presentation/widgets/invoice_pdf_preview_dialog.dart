import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/invoices_localizations.dart';

/// Read-only preview; delivery actions reauthorize through their use cases.
final class InvoicePdfPreviewDialog extends StatelessWidget {
  final Uint8List bytes;

  const InvoicePdfPreviewDialog({required this.bytes, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.invoicesL10n;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.invoicePdfPreviewMaxWidth,
          maxHeight: AppSizes.invoicePdfPreviewMaxHeight,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.pdfPreview,
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
