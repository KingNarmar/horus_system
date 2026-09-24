import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('compile-time environment access stays inside core config', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final violations = <String>[];
    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final content = file.readAsStringSync();
      final readsCompileTimeEnvironment =
          content.contains('String.fromEnvironment') ||
          content.contains('bool.fromEnvironment');
      if (readsCompileTimeEnvironment &&
          normalizedPath != 'lib/core/config/app_config.dart') {
        violations.add(normalizedPath);
      }
      if (content.contains('flutter_dotenv') || content.contains('dotenv.')) {
        violations.add(normalizedPath);
      }
    }

    expect(violations, isEmpty);
  });

  test('pubspec does not bundle runtime environment files', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, isNot(contains('flutter_dotenv')));
    expect(pubspec, isNot(contains('- .env')));
  });

  test('production config source does not embed secret-key prefix marker', () {
    final configSource = File(
      'lib/core/config/app_config.dart',
    ).readAsStringSync();

    expect(configSource, isNot(contains('sb_secret_')));
  });
}
