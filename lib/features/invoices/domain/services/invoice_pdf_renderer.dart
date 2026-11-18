import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/invoice_pdf_document.dart';
import '../entities/invoice_pdf_labels.dart';

/// Data implements PDF and font SDK interactions behind this pure contract.
abstract interface class InvoicePdfRenderer {
  Future<Result<Uint8List>> render({
    required InvoicePdfDocument document,
    required InvoicePdfLabels labels,
  });
}
