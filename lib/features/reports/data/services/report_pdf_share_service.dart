import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/repositories/report_pdf_delivery_repository.dart';
import '../constants/report_pdf_share_constants.dart';

typedef ReportPdfShareCallback =
    Future<ShareResult> Function(ShareParams params);

/// Stages a file in app-private cache for the platform's native share chooser.
final class ReportPdfShareService {
  final Future<Directory> Function() _temporaryDirectory;
  final ReportPdfShareCallback _nativeShare;
  final DateTime Function() _now;
  final bool _isWindows;

  ReportPdfShareService({
    Future<Directory> Function()? temporaryDirectory,
    ReportPdfShareCallback? nativeShare,
    DateTime Function()? now,
    bool? isWindows,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _nativeShare = nativeShare ?? SharePlus.instance.share,
       _now = now ?? DateTime.now,
       _isWindows = isWindows ?? Platform.isWindows;

  Future<ReportPdfDeliveryOutcome> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final cache = await _temporaryDirectory();
    final root = Directory(
      '${cache.path}${Platform.pathSeparator}'
      '${ReportPdfShareConstants.rootDirectory}',
    );
    await root.create(recursive: true);
    await _deleteExpiredShares(root);

    final session = await root.createTemp(
      ReportPdfShareConstants.sessionPrefix,
    );
    try {
      final safeName = fileName.replaceAll(
        ReportPdfShareConstants.unsafeFileNameChars,
        '_',
      );
      final file = File('${session.path}${Platform.pathSeparator}$safeName');
      await file.writeAsBytes(bytes, flush: true);
      final nativePath = _isWindows
          ? file.path.replaceAll('/', r'\')
          : file.path;
      final result = await _nativeShare(
        ShareParams(
          files: [
            XFile(nativePath, mimeType: ReportPdfShareConstants.mimeType),
          ],
          text: _isWindows ? safeName : null,
          subject: safeName,
        ),
      );
      if (result.status == ShareResultStatus.dismissed) {
        await session.delete(recursive: true);
        return ReportPdfDeliveryOutcome.cancelled;
      }
      if (_isWindows || result.status == ShareResultStatus.unavailable) {
        return ReportPdfDeliveryOutcome.initiated;
      }
      return ReportPdfDeliveryOutcome.completed;
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
          .startsWith(ReportPdfShareConstants.sessionPrefix)) {
        continue;
      }
      final age = _now().difference((await entry.stat()).modified);
      if (age > ReportPdfShareConstants.maxCacheAge) {
        await entry.delete(recursive: true);
      }
    }
  }
}
