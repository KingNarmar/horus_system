import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:horus_system/features/invoices/data/services/invoice_pdf_share_service.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoice_pdf_delivery_repository.dart';

void main() {
  late Directory cache;
  setUp(() async {
    cache = await Directory.systemTemp.createTemp('horus-share-test-');
  });
  tearDown(() async {
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  test('Windows stages private PDF and supplies the text payload', () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    ShareParams? captured;
    final share = InvoicePdfShareService(
      isWindows: true,
      temporaryDirectory: () async => cache,
      nativeShare: (params) async {
        captured = params;
        expect(params.text, 'INV-2026-0001.pdf');
        expect(params.files, hasLength(1));
        final path = params.files!.single.path.replaceAll(
          '\\',
          Platform.pathSeparator,
        );
        expect(await File(path).readAsBytes(), bytes);
        return const ShareResult('', ShareResultStatus.success);
      },
    );
    final result = await share.share(
      bytes: bytes,
      fileName: 'INV-2026-0001.pdf',
    );
    expect(result, InvoicePdfDeliveryOutcome.initiated);
    expect(captured?.files?.single.mimeType, 'application/pdf');
  });

  test('dismissed share removes staged file', () async {
    String? path;
    final share = InvoicePdfShareService(
      isWindows: false,
      temporaryDirectory: () async => cache,
      nativeShare: (params) async {
        path = params.files!.single.path;
        return const ShareResult('', ShareResultStatus.dismissed);
      },
    );
    final result = await share.share(
      bytes: Uint8List.fromList([37, 80, 68, 70]),
      fileName: 'invoice.pdf',
    );
    expect(result, InvoicePdfDeliveryOutcome.cancelled);
    expect(await File(path!).exists(), isFalse);
  });

  test('unavailable share result is not misreported as sent', () async {
    final share = InvoicePdfShareService(
      isWindows: false,
      temporaryDirectory: () async => cache,
      nativeShare: (_) async =>
          const ShareResult('', ShareResultStatus.unavailable),
    );
    expect(
      await share.share(
        bytes: Uint8List.fromList([37, 80, 68, 70]),
        fileName: 'invoice.pdf',
      ),
      InvoicePdfDeliveryOutcome.initiated,
    );
  });

  test('native error cleans up the private staged file', () async {
    String? path;
    final share = InvoicePdfShareService(
      isWindows: false,
      temporaryDirectory: () async => cache,
      nativeShare: (params) async {
        path = params.files!.single.path;
        throw StateError('native error');
      },
    );
    await expectLater(
      () => share.share(
        bytes: Uint8List.fromList([37, 80, 68, 70]),
        fileName: 'invoice.pdf',
      ),
      throwsA(isA<StateError>()),
    );
    expect(await File(path!).exists(), isFalse);
  });

  test('cleans only expired share sessions, not unrelated folders', () async {
    final share = InvoicePdfShareService(
      isWindows: false,
      temporaryDirectory: () async => cache,
      now: () => DateTime.now().add(const Duration(days: 3)),
      nativeShare: (_) async =>
          const ShareResult('', ShareResultStatus.dismissed),
    );
    final root = Directory(
      '${cache.path}${Platform.pathSeparator}horus_invoice_pdf_shares',
    );
    await root.create(recursive: true);
    final stale = await root.createTemp('invoice_share_');
    await File(
      '${stale.path}${Platform.pathSeparator}secret.pdf',
    ).writeAsString('secret');
    final unrelated = Directory(
      '${root.path}${Platform.pathSeparator}not_an_invoice',
    );
    await unrelated.create();
    await share.share(
      bytes: Uint8List.fromList([37, 80, 68, 70]),
      fileName: 'invoice.pdf',
    );
    expect(await stale.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
  });
}
