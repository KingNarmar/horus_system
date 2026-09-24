import 'package:horus_system/core/bootstrap/bootstrap_failure.dart';
import 'package:horus_system/core/bootstrap/presentation/bootstrap_failure_localizations.dart';
import 'package:test/test.dart';

void main() {
  test('bootstrap failure copy is localized in English and Arabic', () {
    final english = BootstrapFailureLocalizations.resolve(
      languageCode: 'en',
      code: BootstrapFailureCode.invalidConfiguration,
    );
    final arabic = BootstrapFailureLocalizations.resolve(
      languageCode: 'ar',
      code: BootstrapFailureCode.invalidConfiguration,
    );

    expect(english.title, isNotEmpty);
    expect(english.message, isNotEmpty);
    expect(arabic.title, isNotEmpty);
    expect(arabic.message, isNotEmpty);
    expect(arabic.title, isNot(english.title));
    expect(arabic.message, isNot(english.message));
  });

  test('bootstrap failure copy never exposes internal failure codes', () {
    for (final code in BootstrapFailureCode.values) {
      final copy = BootstrapFailureLocalizations.resolve(
        languageCode: 'en',
        code: code,
      );
      expect(copy.title, isNot(contains(code.name)));
      expect(copy.message, isNot(contains(code.name)));
    }
  });
}
