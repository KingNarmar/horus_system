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
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return BusinessDocumentFile(bytes: bytes, fileName: file.name);
  }
}
