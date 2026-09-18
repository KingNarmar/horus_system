import 'package:url_launcher/url_launcher.dart';

final class TripDocumentLauncher {
  const TripDocumentLauncher();

  Future<bool> open(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
