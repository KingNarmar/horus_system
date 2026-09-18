import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/documents/domain/entities/business_document_file.dart';

enum TripDocumentPickSource { file, gallery, camera }

final class TripDocumentPicker {
  static const List<String> _allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  ];

  final ImagePicker _imagePicker;

  TripDocumentPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  bool get supportsImageCapture {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<BusinessDocumentFile?> pick(TripDocumentPickSource source) {
    return switch (source) {
      TripDocumentPickSource.file => _pickFile(),
      TripDocumentPickSource.gallery => _pickImage(ImageSource.gallery),
      TripDocumentPickSource.camera => _pickImage(ImageSource.camera),
    };
  }

  Future<BusinessDocumentFile?> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return BusinessDocumentFile(bytes: bytes, fileName: file.name);
  }

  Future<BusinessDocumentFile?> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(source: source);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return BusinessDocumentFile(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType,
    );
  }
}
