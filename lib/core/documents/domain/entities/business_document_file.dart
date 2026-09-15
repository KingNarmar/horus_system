import 'dart:typed_data';

final class BusinessDocumentFile {
  final Uint8List bytes;
  final String fileName;
  final String? mimeType;

  const BusinessDocumentFile({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });

  int get sizeInBytes => bytes.lengthInBytes;
}
