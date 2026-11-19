import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/invoice_pdf_document.dart';
import '../entities/invoice_pdf_labels.dart';
import '../services/invoice_pdf_renderer.dart';
import 'prepare_invoice_pdf_usecase.dart';

final class GenerateInvoicePdfParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;
  final InvoicePdfLabels labels;

  const GenerateInvoicePdfParams({
    required this.currentCompanyContext,
    required this.invoiceId,
    required this.labels,
  });
}

final class GenerateInvoicePdfUseCase {
  final PrepareInvoicePdfUseCase _prepare;
  final InvoicePdfRenderer _renderer;

  const GenerateInvoicePdfUseCase({
    required PrepareInvoicePdfUseCase prepare,
    required InvoicePdfRenderer renderer,
  }) : _prepare = prepare,
       _renderer = renderer;

  Future<Result<Uint8List>> call(GenerateInvoicePdfParams params) async {
    final prepared = await _prepare(
      PrepareInvoicePdfParams(
        currentCompanyContext: params.currentCompanyContext,
        invoiceId: params.invoiceId,
      ),
    );
    if (prepared is FailureResult<InvoicePdfDocument>) {
      return FailureResult(prepared.failure);
    }
    return _renderer.render(
      document: (prepared as Success<InvoicePdfDocument>).data,
      labels: params.labels,
    );
  }
}
