import 'dart:typed_data';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/invoice_pdf_delivery_repository.dart';

enum InvoicePdfAction { preview, save, print, share }

sealed class InvoicePdfState {
  const InvoicePdfState();
}

final class InvoicePdfIdle extends InvoicePdfState {
  const InvoicePdfIdle();
}

final class InvoicePdfBusy extends InvoicePdfState {
  final InvoicePdfAction action;

  const InvoicePdfBusy(this.action);
}

final class InvoicePdfPreviewReady extends InvoicePdfState {
  final Uint8List bytes;

  const InvoicePdfPreviewReady(this.bytes);
}

final class InvoicePdfCompleted extends InvoicePdfState {
  final InvoicePdfAction action;
  final InvoicePdfDeliveryOutcome outcome;

  const InvoicePdfCompleted(this.action, this.outcome);
}

final class InvoicePdfFailed extends InvoicePdfState {
  final Failure failure;

  const InvoicePdfFailed(this.failure);
}
