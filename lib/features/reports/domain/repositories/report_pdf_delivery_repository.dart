import 'dart:typed_data';

import '../../../../core/utils/result.dart';

enum ReportPdfDeliveryOutcome { completed, cancelled, initiated }

/// File delivery is a platform concern; Domain knows no plugins or paths.
abstract interface class ReportPdfDeliveryRepository {
  Future<Result<ReportPdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  });

  Future<Result<ReportPdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
  });

  Future<Result<ReportPdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  });
}
