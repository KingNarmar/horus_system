import 'dart:typed_data';

/// Selected branding bytes; no Flutter, Storage SDK or platform dependency.
final class CompanyBrandLogoFile {
  final Uint8List bytes;
  final String fileName;

  const CompanyBrandLogoFile({required this.bytes, required this.fileName});
}
