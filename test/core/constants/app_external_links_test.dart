import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/constants/app_external_links.dart';

void main() {
  group('AppExternalLinks', () {
    test('uses public HTTPS H.O.R.U.S legal and support URLs', () {
      expect(
        AppExternalLinks.horusPrivacyPolicy.toString(),
        'https://kingnarmar.com/horus/privacy-policy',
      );
      expect(
        AppExternalLinks.horusTerms.toString(),
        'https://kingnarmar.com/horus/terms',
      );
      expect(
        AppExternalLinks.horusSupport.toString(),
        'https://kingnarmar.com/horus/support',
      );
    });

    test('uses the dedicated H.O.R.U.S support mailbox', () {
      expect(
        AppExternalLinks.horusSupportEmail.toString(),
        'mailto:support.horus@kingnarmar.com',
      );
    });
  });
}
