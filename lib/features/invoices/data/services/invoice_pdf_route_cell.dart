import 'package:pdf/widgets.dart' as pw;

import '../constants/invoice_pdf_style.dart';

/// Keeps origin → destination in business order even in an Arabic table.
/// A nested LTR run isolates route identifiers, punctuation, and Arabic words
/// from the page's RTL direction without changing the rest of the table.
abstract final class InvoicePdfRouteCell {
  static pw.Widget build({
    required String? loadingLocation,
    required String? unloadingLocation,
    required String unavailable,
  }) {
    final route = [loadingLocation, unloadingLocation]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' → ');

    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Text(
        route.isEmpty ? unavailable : route,
        textDirection: pw.TextDirection.ltr,
        textAlign: pw.TextAlign.left,
        softWrap: true,
        style: const pw.TextStyle(fontSize: InvoicePdfStyle.bodySize),
      ),
    );
  }
}
