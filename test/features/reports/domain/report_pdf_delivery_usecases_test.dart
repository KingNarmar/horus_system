import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/reports/domain/failures/reports_failure_codes.dart';
import 'package:horus_system/features/reports/domain/repositories/report_pdf_delivery_repository.dart';
import 'package:horus_system/features/reports/domain/usecases/report_pdf_delivery_usecases.dart';

void main() {
  final validBytes = Uint8List.fromList([37, 80, 68, 70]);

  test('save rejects invalid documents before platform access', () async {
    final repository = _DeliveryRepository();
    final useCase = SaveReportPdfUseCase(repository);

    final empty = await useCase(
      ReportPdfDeliveryParams(bytes: Uint8List(0), fileName: 'report.pdf'),
    );
    final extension = await useCase(
      ReportPdfDeliveryParams(bytes: validBytes, fileName: 'report.txt'),
    );

    expect(empty.failureOrNull?.code, ReportsFailureCodes.pdfInvalidDocument);
    expect(
      extension.failureOrNull?.code,
      ReportsFailureCodes.pdfInvalidDocument,
    );
    expect(repository.saveCalls, 0);
  });

  test('invalid print and share are denied', () async {
    final repository = _DeliveryRepository();
    final invalid = ReportPdfDeliveryParams(
      bytes: validBytes,
      fileName: 'report.xlsx',
    );

    final printResult = await PrintReportPdfUseCase(repository)(invalid);
    final shareResult = await ShareReportPdfUseCase(repository)(invalid);

    expect(
      printResult.failureOrNull?.code,
      ReportsFailureCodes.pdfInvalidDocument,
    );
    expect(
      shareResult.failureOrNull?.code,
      ReportsFailureCodes.pdfInvalidDocument,
    );
    expect(repository.printCalls, 0);
    expect(repository.shareCalls, 0);
  });

  test('valid save forwards exact bytes and filename', () async {
    final repository = _DeliveryRepository();
    final params = ReportPdfDeliveryParams(
      bytes: validBytes,
      fileName: 'horus_report_dailyTrips.pdf',
    );

    final result = await SaveReportPdfUseCase(repository)(params);

    expect(result.dataOrNull, ReportPdfDeliveryOutcome.completed);
    expect(repository.saveCalls, 1);
    expect(identical(repository.lastBytes, validBytes), isTrue);
    expect(repository.lastFileName, params.fileName);
    expect(repository.printCalls, 0);
    expect(repository.shareCalls, 0);
  });

  test('print cancellation and share initiation are preserved', () async {
    final repository = _DeliveryRepository(
      printResult: const Success(ReportPdfDeliveryOutcome.cancelled),
      shareResult: const Success(ReportPdfDeliveryOutcome.initiated),
    );
    final params = ReportPdfDeliveryParams(
      bytes: validBytes,
      fileName: 'horus_report_dailyTrips.pdf',
    );

    final printed = await PrintReportPdfUseCase(repository)(params);
    final shared = await ShareReportPdfUseCase(repository)(params);

    expect(printed.dataOrNull, ReportPdfDeliveryOutcome.cancelled);
    expect(shared.dataOrNull, ReportPdfDeliveryOutcome.initiated);
    expect(repository.printCalls, 1);
    expect(repository.shareCalls, 1);
  });

  test('delivery failure remains typed and is not swallowed', () async {
    final repository = _DeliveryRepository(
      saveResult: const FailureResult(
        ServerFailure(code: ReportsFailureCodes.pdfSaveUnavailable),
      ),
    );
    final result = await SaveReportPdfUseCase(repository)(
      ReportPdfDeliveryParams(
        bytes: validBytes,
        fileName: 'horus_report_dailyTrips.pdf',
      ),
    );

    expect(result.failureOrNull?.code, ReportsFailureCodes.pdfSaveUnavailable);
    expect(repository.saveCalls, 1);
  });
}

final class _DeliveryRepository implements ReportPdfDeliveryRepository {
  final Result<ReportPdfDeliveryOutcome> saveResult;
  final Result<ReportPdfDeliveryOutcome> printResult;
  final Result<ReportPdfDeliveryOutcome> shareResult;

  int saveCalls = 0;
  int printCalls = 0;
  int shareCalls = 0;
  Uint8List? lastBytes;
  String? lastFileName;

  _DeliveryRepository({
    this.saveResult = const Success(ReportPdfDeliveryOutcome.completed),
    this.printResult = const Success(ReportPdfDeliveryOutcome.completed),
    this.shareResult = const Success(ReportPdfDeliveryOutcome.completed),
  });

  @override
  Future<Result<ReportPdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    saveCalls++;
    lastBytes = bytes;
    lastFileName = fileName;
    return saveResult;
  }

  @override
  Future<Result<ReportPdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
  }) async {
    printCalls++;
    lastBytes = bytes;
    lastFileName = fileName;
    return printResult;
  }

  @override
  Future<Result<ReportPdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    shareCalls++;
    lastBytes = bytes;
    lastFileName = fileName;
    return shareResult;
  }
}
