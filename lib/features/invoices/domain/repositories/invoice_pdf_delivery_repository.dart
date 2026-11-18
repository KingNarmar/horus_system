import 'dart:typed_data';

import '../../../../core/utils/result.dart';

enum InvoicePdfDeliveryOutcome { completed, cancelled }

/// Pure delivery contract. Platform plugins are Data implementation details.
abstract interface class InvoicePdfDeliveryRepository {
  Future<Result<InvoicePdfDeliveryOutcome>> save({
    required Uint8List bytes,
    required String fileName,
  });

  Future<Result<InvoicePdfDeliveryOutcome>> print({
    required Uint8List bytes,
    required String fileName,
  });

  Future<Result<InvoicePdfDeliveryOutcome>> share({
    required Uint8List bytes,
    required String fileName,
  });
}
