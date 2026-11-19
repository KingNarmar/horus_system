import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/invoice_pdf_style.dart';

/// Keeps loading -> unloading in business order, while shaping each location
/// with its own script direction. The arrow is vector artwork so no font
/// needs to contain an arrow glyph.
abstract final class InvoicePdfRouteCell {
  static final RegExp _arabicScript = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  static pw.Widget build({
    required String? loadingLocation,
    required String? unloadingLocation,
    required String unavailable,
  }) {
    final loading = loadingLocation?.trim();
    final unloading = unloadingLocation?.trim();
    final hasLoading = loading != null && loading.isNotEmpty;
    final hasUnloading = unloading != null && unloading.isNotEmpty;

    // The outer LTR context locks the trip sequence: loading, arrow, unloading.
    // Each nested Text shapes Arabic in RTL, without reversing the journey or
    // forcing Latin-only names through the RTL layout algorithm.
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
                  pw.WidgetSpan(child: _locationText(loading)),
                  const pw.TextSpan(text: ' '),
                  pw.WidgetSpan(child: _directionArrow()),
                  const pw.TextSpan(text: ' '),
                  pw.WidgetSpan(child: _locationText(unloading)),
                ],
              ),
            )
          : _locationText(
              hasLoading
                  ? loading
                  : hasUnloading
                  ? unloading
                  : unavailable,
            ),
    );
  }

  static pw.Text _locationText(String value) {
    return pw.Text(
      value,
      textDirection: _arabicScript.hasMatch(value)
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr,
      textAlign: pw.TextAlign.start,
      softWrap: true,
      style: const pw.TextStyle(fontSize: InvoicePdfStyle.bodySize),
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
