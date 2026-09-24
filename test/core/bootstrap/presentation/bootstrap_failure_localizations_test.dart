import 'package:flutter/widgets.dart';
import 'package:horus_system/core/bootstrap/bootstrap_failure.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:test/test.dart';

void main() {
  test('bootstrap failure copy is localized in English and Arabic', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final arabic = lookupAppLocalizations(const Locale('ar'));

    expect(english.bootstrapFailureTitle, isNotEmpty);
    expect(english.bootstrapInvalidConfigurationMessage, isNotEmpty);
    expect(english.bootstrapServiceInitializationFailedMessage, isNotEmpty);
    expect(arabic.bootstrapFailureTitle, isNotEmpty);
    expect(arabic.bootstrapInvalidConfigurationMessage, isNotEmpty);
    expect(arabic.bootstrapServiceInitializationFailedMessage, isNotEmpty);
    expect(arabic.bootstrapFailureTitle, isNot(english.bootstrapFailureTitle));
  });

  test('bootstrap localized messages never expose internal failure codes', () {
    for (final localizations in <AppLocalizations>[
      lookupAppLocalizations(const Locale('en')),
      lookupAppLocalizations(const Locale('ar')),
    ]) {
      for (final code in BootstrapFailureCode.values) {
        final message = switch (code) {
          BootstrapFailureCode.invalidConfiguration =>
            localizations.bootstrapInvalidConfigurationMessage,
          BootstrapFailureCode.serviceInitializationFailed =>
            localizations.bootstrapServiceInitializationFailedMessage,
        };

        expect(localizations.bootstrapFailureTitle, isNot(contains(code.name)));
        expect(message, isNot(contains(code.name)));
      }
    }
  });
}
