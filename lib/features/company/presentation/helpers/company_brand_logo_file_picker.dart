import 'package:file_picker/file_picker.dart';

import '../../domain/entities/company_brand_logo_file.dart';

/// Platform file access is a Presentation concern, never Supabase access.
final class CompanyBrandLogoFilePicker {
  const CompanyBrandLogoFilePicker();

  Future<CompanyBrandLogoFile?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (file == null) return null;
    return CompanyBrandLogoFile(
      bytes: await file.readAsBytes(),
      fileName: file.name,
    );
  }
}
