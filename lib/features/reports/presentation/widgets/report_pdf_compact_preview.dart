import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/reports_localizations.dart';

/// A full-screen, gesture- and button-zoomable PDF reader on narrow screens.
///
/// The source PDF is immutable; save/share/print remain separate authorized
/// actions on the Reports page.
final class ReportPdfCompactPreview extends StatefulWidget {
  final Uint8List bytes;

  const ReportPdfCompactPreview({required this.bytes, super.key});

  @override
  State<ReportPdfCompactPreview> createState() =>
      _ReportPdfCompactPreviewState();
}

final class _ReportPdfCompactPreviewState
    extends State<ReportPdfCompactPreview> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeZoom(double delta) {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale + delta)
        .clamp(
          AppSizes.reportPdfPreviewMinZoom,
          AppSizes.reportPdfPreviewMaxZoom,
        )
        .toDouble();
    if (nextScale == currentScale) return;

    // InteractiveViewer only supports translation and uniform scaling here.
    // Preserve the panned position when adjusting the scale.
    final matrix = _controller.value.clone()
      ..setEntry(0, 0, nextScale)
      ..setEntry(1, 1, nextScale);
    _controller.value = matrix;
  }

  void _fitPage() {
    _controller.value = _controller.value.clone()..setIdentity();
  }

  Widget _buildZoomablePages(
    BuildContext context,
    List<PdfPreviewPageData> pages,
  ) => LayoutBuilder(
    builder: (context, constraints) => InteractiveViewer(
      transformationController: _controller,
      minScale: AppSizes.reportPdfPreviewMinZoom,
      maxScale: AppSizes.reportPdfPreviewMaxZoom,
      alignment: Alignment.topCenter,
      constrained: false,
      child: SizedBox(
        width: constraints.maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final page in pages)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AspectRatio(
                  aspectRatio: page.aspectRatio,
                  child: Image(image: page.image, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
      ),
    ),
  );

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
        build: (_) async => widget.bytes,
        dpi: AppSizes.reportPdfPreviewMobileDpi,
        pagesBuilder: _buildZoomablePages,
        onError: (_, _) => Center(
          child: Text(
            strings.exportPdfRenderFailure,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = _controller.value.getMaxScaleOnAxis();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: strings.exportPdfZoomOut,
                    onPressed: scale <= AppSizes.reportPdfPreviewMinZoom
                        ? null
                        : () => _changeZoom(-AppSizes.reportPdfPreviewZoomStep),
                    icon: const Icon(AppIcons.reportPdfZoomOut),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text('${(scale * 100).round()}%'),
                  ),
                  IconButton(
                    tooltip: strings.exportPdfZoomIn,
                    onPressed: scale >= AppSizes.reportPdfPreviewMaxZoom
                        ? null
                        : () => _changeZoom(AppSizes.reportPdfPreviewZoomStep),
                    icon: const Icon(AppIcons.reportPdfZoomIn),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: strings.exportPdfFitPage,
                    onPressed: _fitPage,
                    icon: const Icon(AppIcons.reportPdfFitPage),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
