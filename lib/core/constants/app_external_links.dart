abstract final class AppExternalLinks {
  const AppExternalLinks._();

  static final Uri horusPrivacyPolicy = Uri.https(
    'kingnarmar.com',
    '/horus/privacy-policy',
  );
  static final Uri horusTerms = Uri.https('kingnarmar.com', '/horus/terms');
  static final Uri horusSupport = Uri.https('kingnarmar.com', '/horus/support');
  static final Uri horusAccountDeletion = Uri.https(
    'kingnarmar.com',
    '/horus/account-deletion',
  );
  static final Uri horusSupportEmail = Uri(
    scheme: 'mailto',
    path: 'support.horus@kingnarmar.com',
  );
}
