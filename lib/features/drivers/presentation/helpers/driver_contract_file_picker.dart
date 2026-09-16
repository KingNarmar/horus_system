import 'package:file_picker/file_picker.dart';

import '../../../../core/documents/domain/entities/business_document_file.dart';

final class DriverContractFilePicker {
  static const List<String> _allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  ];

  const DriverContractFilePicker();

  Future<BusinessDocumentFile?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('Selected contract file bytes are unavailable.');
    }

    return BusinessDocumentFile(bytes: bytes, fileName: file.name);
  }
}
