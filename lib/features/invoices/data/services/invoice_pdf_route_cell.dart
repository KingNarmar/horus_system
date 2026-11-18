import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/invoice_pdf_style.dart';

/// Keeps the origin and destination in business order in EN/AR invoices.
/// The directional arrow is vector artwork, not a font glyph: Cairo and
/// other PDF fonts do not consistently include Unicode arrow characters.
abstract final class InvoicePdfRouteCell {
  static pw.Widget build({
    required String? loadingLocation,
    required String? unloadingLocation,
    required String unavailable,
  }) {
    final loading = loadingLocation?.trim();
    final unloading = unloadingLocation?.trim();
    final hasLoading = loading != null && loading.isNotEmpty;
    final hasUnloading = unloading != null && unloading.isNotEmpty;

    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: hasLoading && hasUnloading
          ? pw.RichText(
              textDirection: pw.TextDirection.ltr,
              textAlign: pw.TextAlign.left,
              softWrap: true,
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: InvoicePdfStyle.bodySize),
                children: [
                  pw.TextSpan(text: '$loading '),
                  pw.WidgetSpan(child: _directionArrow()),
                  pw.TextSpan(text: ' $unloading'),
                ],
              ),
            )
          : pw.Text(
              hasLoading
                  ? loading
                  : hasUnloading
                  ? unloading
                  : unavailable,
              textDirection: pw.TextDirection.ltr,
              textAlign: pw.TextAlign.left,
              softWrap: true,
              style: const pw.TextStyle(fontSize: InvoicePdfStyle.bodySize),
            ),
    );
  }

  static pw.Widget _directionArrow() {
    return pw.CustomPaint(
      size: const PdfPoint(
        InvoicePdfStyle.routeArrowWidth,
        InvoicePdfStyle.routeArrowHeight,
      ),
      painter: (canvas, size) {
        final centerY = size.y / 2;
        final tipX = size.x - InvoicePdfStyle.routeArrowStroke;
        final headX = tipX - InvoicePdfStyle.routeArrowHeadSize;
        final headY = InvoicePdfStyle.routeArrowHeadSize / 2;

        canvas.saveContext();
        canvas.setStrokeColor(PdfColors.black);
        canvas.setLineWidth(InvoicePdfStyle.routeArrowStroke);
        canvas.moveTo(0, centerY);
        canvas.lineTo(tipX, centerY);
        canvas.moveTo(headX, centerY + headY);
        canvas.lineTo(tipX, centerY);
        canvas.lineTo(headX, centerY - headY);
        canvas.strokePath();
        canvas.restoreContext();
      },
    );
  }
}
