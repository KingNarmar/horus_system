import 'dart:typed_data';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../failures/invoice_failure_codes.dart';
import '../repositories/invoice_pdf_delivery_repository.dart';

final class InvoicePdfDeliveryParams {
  final Uint8List bytes;
  final String fileName;

  const InvoicePdfDeliveryParams({required this.bytes, required this.fileName});
}

abstract class _InvoicePdfDeliveryValidator {
  static Result<InvoicePdfDeliveryParams> validate(
    InvoicePdfDeliveryParams params,
  ) {
    if (params.bytes.isEmpty || !params.fileName.endsWith('.pdf')) {
      return const FailureResult(
        ValidationFailure(code: InvoiceFailureCodes.pdfInvalidDocument),
      );
    }
    return Success(params);
  }
}

final class SaveInvoicePdfUseCase {
  final InvoicePdfDeliveryRepository _repository;

  const SaveInvoicePdfUseCase(this._repository);

  Future<Result<InvoicePdfDeliveryOutcome>> call(
    InvoicePdfDeliveryParams params,
  ) async {
    final validated = _InvoicePdfDeliveryValidator.validate(params);
    if (validated.failureOrNull != null) {
      return FailureResult(validated.failureOrNull!);
    }
    return _repository.save(bytes: params.bytes, fileName: params.fileName);
  }
}

final class PrintInvoicePdfUseCase {
  final InvoicePdfDeliveryRepository _repository;

  const PrintInvoicePdfUseCase(this._repository);

  Future<Result<InvoicePdfDeliveryOutcome>> call(
    InvoicePdfDeliveryParams params,
  ) async {
    final validated = _InvoicePdfDeliveryValidator.validate(params);
    if (validated.failureOrNull != null) {
      return FailureResult(validated.failureOrNull!);
    }
    return _repository.print(bytes: params.bytes, fileName: params.fileName);
  }
}

final class ShareInvoicePdfUseCase {
  final InvoicePdfDeliveryRepository _repository;

  const ShareInvoicePdfUseCase(this._repository);

  Future<Result<InvoicePdfDeliveryOutcome>> call(
    InvoicePdfDeliveryParams params,
  ) async {
    final validated = _InvoicePdfDeliveryValidator.validate(params);
    if (validated.failureOrNull != null) {
      return FailureResult(validated.failureOrNull!);
    }
    return _repository.share(bytes: params.bytes, fileName: params.fileName);
  }
}
