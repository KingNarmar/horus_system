import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

final class TripDocumentSaver {
  const TripDocumentSaver();

  Future<bool> save({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String dialogTitle,
  }) async {
    final result = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return result != null;
  }
}
