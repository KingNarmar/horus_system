import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../localization/reports_localizations.dart';

/// Displays rasterized PDF pages with coordinated touch and button zoom.
///
/// A separate widget lets geometry and gestures be tested without native PDF
/// rasterization, while ReportPdfCompactPreview owns the PDF lifecycle.
final class ReportPdfPageViewer extends StatefulWidget {
  final List<PdfPreviewPageData> pages;

  const ReportPdfPageViewer({required this.pages, super.key});

  @override
  State<ReportPdfPageViewer> createState() => _ReportPdfPageViewerState();
}

final class _ReportPdfPageViewerState extends State<ReportPdfPageViewer> {
  final TransformationController _controller = TransformationController();
  final GlobalKey _viewportKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

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

    final viewport = _viewportKey.currentContext?.findRenderObject();
    final content = _contentKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || content is! RenderBox) return;

    final viewportSize = viewport.size;
    final contentSize = content.size;
    if (viewportSize.isEmpty || contentSize.isEmpty) return;

    // Keep the same scene point under the viewport center, then constrain the
    // resulting translation so no page edge becomes unreachable.
    final center = viewportSize.center(Offset.zero);
    final sceneCenter = _controller.toScene(center);
    final translationX = _clampTranslation(
      center.dx - sceneCenter.dx * nextScale,
      viewportSize.width,
      contentSize.width * nextScale,
    );
    final translationY = _clampTranslation(
      center.dy - sceneCenter.dy * nextScale,
      viewportSize.height,
      contentSize.height * nextScale,
    );
    _controller.value = Matrix4.identity()
      ..setEntry(0, 0, nextScale)
      ..setEntry(1, 1, nextScale)
      ..setTranslationRaw(translationX, translationY, 0);
  }

  double _clampTranslation(
    double translation,
    double viewportExtent,
    double scaledContentExtent,
  ) {
    final minimum = math.min(0.0, viewportExtent - scaledContentExtent);
    return translation.clamp(minimum, 0.0).toDouble();
  }

  void _fitPage() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.reportsL10n;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => InteractiveViewer(
              key: _viewportKey,
              transformationController: _controller,
              minScale: AppSizes.reportPdfPreviewMinZoom,
              maxScale: AppSizes.reportPdfPreviewMaxZoom,
              constrained: false,
              child: SizedBox(
                width: constraints.maxWidth,
                child: ConstrainedBox(
                  key: _contentKey,
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final page in widget.pages)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: AspectRatio(
                            aspectRatio: page.aspectRatio,
                            child: Image(
                              image: page.image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
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
      ],
    );
  }
}
