import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/repositories/invoice_pdf_delivery_repository.dart';
import '../constants/invoice_pdf_share_constants.dart';

typedef InvoicePdfShareCallback = Future<ShareResult> Function(
  ShareParams params,
);

/// Stages PDFs in app-private cache for the native share sheet.
/// A recipient might read after the chooser closes, so successful/unknown
/// shares expire on the next share call; cancelled/failed ones are removed.
final class InvoicePdfShareService {
  final Future<Directory> Function() _temporaryDirectory;
  final InvoicePdfShareCallback _nativeShare;
  final DateTime Function() _now;
  final bool _isWindows;

  InvoicePdfShareService({
    Future<Directory> Function()? temporaryDirectory,
    InvoicePdfShareCallback? nativeShare,
    DateTime Function()? now,
    bool? isWindows,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _nativeShare = nativeShare ?? SharePlus.instance.share,
       _now = now ?? DateTime.now,
       _isWindows = isWindows ?? Platform.isWindows;

  Future<InvoicePdfDeliveryOutcome> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final cache = await _temporaryDirectory();
    final root = Directory(
      '${cache.path}${Platform.pathSeparator}'
      '${InvoicePdfShareConstants.rootDirectory}',
    );
    await root.create(recursive: true);
    await _deleteExpiredShares(root);

    final session = await root.createTemp(
      InvoicePdfShareConstants.sessionPrefix,
    );
    try {
      final name = fileName.replaceAll(
        InvoicePdfShareConstants.unsafeFileNameChars,
        '_',
      );
      final file = File('${session.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(bytes, flush: true);
      final nativePath = _isWindows
          ? file.path.replaceAll('/', r'\')
          : file.path;
      final result = await _nativeShare(
        ShareParams(
          files: [
            XFile(nativePath, mimeType: InvoicePdfShareConstants.mimeType),
          ],
          // Windows share_plus 11.x can need text alongside a file.
          text: _isWindows ? name : null,
          subject: name,
        ),
      );
      if (result.status == ShareResultStatus.dismissed) {
        await session.delete(recursive: true);
        return InvoicePdfDeliveryOutcome.cancelled;
      }
      if (_isWindows || result.status == ShareResultStatus.unavailable) {
        return InvoicePdfDeliveryOutcome.initiated;
      }
      return InvoicePdfDeliveryOutcome.completed;
    } catch (_) {
      await session.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> _deleteExpiredShares(Directory root) async {
    await for (final entry in root.list(followLinks: false)) {
      if (entry is! Directory) continue;
      if (!entry.path
          .split(Platform.pathSeparator)
          .last
          .startsWith(InvoicePdfShareConstants.sessionPrefix)) {
        continue;
      }
      final age = _now().difference((await entry.stat()).modified);
      if (age > InvoicePdfShareConstants.maxCacheAge) {
        await entry.delete(recursive: true);
      }
    }
  }
}
