import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanup architecture rules', () {
    test('localized server errors do not expose raw failure messages', () {
      final content = _read(
        'lib/core/localization/app_localizations_extension.dart',
      );

      expect(
        content,
        isNot(contains('FailureCodes.serverError =>\n        failure.message')),
      );
      expect(
        content,
        contains('FailureCodes.serverError => _genericServerErrorMessage'),
      );
      expect(content, contains('failure is ServerFailure'));
    });

    test(
      'audited repositories use semantic descriptions instead of English sentences',
      () {
        const repositoryPaths = [
          'lib/features/customers/data/repositories/customers_repository_impl.dart',
          'lib/features/expenses/data/repositories/trip_expense_repo_impl.dart',
          'lib/features/fleet/data/repositories/fleet_repo_impl.dart',
          'lib/features/routes/data/repositories/routes_repository_impl.dart',
          'lib/features/trips/data/repositories/trips_repository_impl.dart',
        ];

        const forbiddenSnippets = [
          'Customer created:',
          'Customer updated:',
          'Customer deactivated:',
          'Customer reactivated:',
          'Trip created:',
          'Trip updated:',
          'Trip status changed:',
          'Trip expense added:',
          'Trip expense updated:',
          'Route created:',
          'Route updated:',
          'Route deactivated:',
          'Route reactivated:',
          'Tractor head created:',
          'Tractor head updated:',
          'Tractor head deactivated:',
          'Tractor head reactivated:',
          'Trailer created:',
          'Trailer updated:',
          'Trailer deactivated:',
          'Trailer reactivated:',
        ];

        for (final path in repositoryPaths) {
          final content = _read(path);
          for (final snippet in forbiddenSnippets) {
            expect(
              content,
              isNot(contains(snippet)),
              reason:
                  '$path must use semantic audit descriptions, not "$snippet".',
            );
          }
        }
      },
    );

    test('domain tests do not import flutter_test', () {
      final domainTestFiles = Directory('test/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('_test.dart') &&
                file.path.split(Platform.pathSeparator).contains('domain'),
          );

      for (final file in domainTestFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNot(contains('package:flutter_test/flutter_test.dart')),
          reason: '${file.path} must use package:test for pure domain tests.',
        );
      }
    });
  });
}

String _read(String path) => File(path).readAsStringSync();
