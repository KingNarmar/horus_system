import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/invoice_pdf_labels.dart';
import '../../domain/repositories/invoice_pdf_delivery_repository.dart';
import '../../domain/usecases/generate_invoice_pdf_usecase.dart';
import '../../domain/usecases/invoice_pdf_delivery_usecases.dart';
import 'invoice_pdf_state.dart';

/// Focused export orchestration, isolated from invoice details and mutations.
final class InvoicePdfCubit extends Cubit<InvoicePdfState> {
  final GenerateInvoicePdfUseCase _generate;
  final SaveInvoicePdfUseCase _save;
  final PrintInvoicePdfUseCase _print;
  final ShareInvoicePdfUseCase _share;

  String? _companyId;
  int _generation = 0;

  InvoicePdfCubit({
    required GenerateInvoicePdfUseCase generate,
    required SaveInvoicePdfUseCase save,
    required PrintInvoicePdfUseCase print,
    required ShareInvoicePdfUseCase share,
  }) : _generate = generate,
       _save = save,
       _print = print,
       _share = share,
       super(const InvoicePdfIdle());

  bool get isBusy => state is InvoicePdfBusy;

  Future<void> perform({
    required InvoicePdfAction action,
    required CurrentCompanyContext currentCompanyContext,
    required String invoiceId,
    required InvoicePdfLabels labels,
    required String fileName,
  }) async {
    if (isBusy || isClosed) return;
    final generation = ++_generation;
    _companyId = currentCompanyContext.companyId;
    emit(InvoicePdfBusy(action));

    final generated = await _generate(
      GenerateInvoicePdfParams(
        currentCompanyContext: currentCompanyContext,
        invoiceId: invoiceId,
        labels: labels,
      ),
    );
    if (!_isCurrent(generation, currentCompanyContext.companyId)) return;
    if (generated.failureOrNull != null) {
      emit(InvoicePdfFailed(generated.failureOrNull!));
      return;
    }

    final bytes = generated.dataOrNull!;
    if (action == InvoicePdfAction.preview) {
      emit(InvoicePdfPreviewReady(bytes));
      return;
    }

    final params = InvoicePdfDeliveryParams(
      bytes: bytes,
      fileName: fileName,
    );
    final Result<InvoicePdfDeliveryOutcome> delivery;
    switch (action) {
      case InvoicePdfAction.save:
        delivery = await _save(params);
      case InvoicePdfAction.print:
        delivery = await _print(params);
      case InvoicePdfAction.share:
        delivery = await _share(params);
      case InvoicePdfAction.preview:
        return;
    }

    if (!_isCurrent(generation, currentCompanyContext.companyId)) return;
    if (delivery.failureOrNull != null) {
      emit(InvoicePdfFailed(delivery.failureOrNull!));
      return;
    }
    emit(InvoicePdfCompleted(action, delivery.dataOrNull!));
  }

  void clearFeedback() {
    if (!isClosed && !isBusy) emit(const InvoicePdfIdle());
  }

  bool _isCurrent(int generation, String companyId) {
    return !isClosed &&
        generation == _generation &&
        _companyId == companyId;
  }
}
