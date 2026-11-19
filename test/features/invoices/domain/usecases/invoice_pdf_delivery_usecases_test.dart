import 'dart:typed_data';

import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/invoices/domain/failures/invoice_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoice_pdf_delivery_repository.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_pdf_delivery_usecases.dart';
import 'package:test/test.dart';

void main() {
  test('invalid PDF is rejected before calling the platform', () async {
    final repository = _Delivery();
    final result = await SaveInvoicePdfUseCase(repository)(
      InvoicePdfDeliveryParams(bytes: Uint8List(0), fileName: 'invoice.pdf'),
    );
    expect(result.failureOrNull?.code, InvoiceFailureCodes.pdfInvalidDocument);
    expect(repository.saves, 0);
  });

  test('save forwards exact bytes and destination filename', () async {
    final repository = _Delivery();
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    final result = await SaveInvoicePdfUseCase(repository)(
      InvoicePdfDeliveryParams(bytes: bytes, fileName: 'INV-2026-0001.pdf'),
    );
    expect(result.dataOrNull, InvoicePdfDeliveryOutcome.completed);
    expect(repository.bytes, same(bytes));
    expect(repository.fileName, 'INV-2026-0001.pdf');
  });

  test('printing and sharing remain separate actions', () async {
    final repository = _Delivery();
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    final params = InvoicePdfDeliveryParams(
      bytes: bytes,
      fileName: 'invoice.pdf',
    );
    await PrintInvoicePdfUseCase(repository)(params);
    await ShareInvoicePdfUseCase(repository)(params);

    expect(repository.prints, 1);
    expect(repository.shares, 1);
    expect(repository.saves, 0);
  });
}

final class _Delivery implements InvoicePdfDeliveryRepository {
  int saves = 0;
  int prints = 0;
  int shares = 0;
  Uint8List? bytes;
  String? fileName;

  @override
  Future<Result<InvoicePdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    saves++;
    this.bytes = bytes;
    this.fileName = fileName;
    return const Success(InvoicePdfDeliveryOutcome.completed);
  }

  @override
  Future<Result<InvoicePdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
  }) async {
    prints++;
    return const Success(InvoicePdfDeliveryOutcome.completed);
  }

  @override
  Future<Result<InvoicePdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    shares++;
    return const Success(InvoicePdfDeliveryOutcome.cancelled);
  }
}
