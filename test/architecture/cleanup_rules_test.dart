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

    test('domain layer does not depend on outer layers or SDKs', () {
      final domainFiles = _dartFilesUnder(
        'lib/features',
      ).where((file) => _normalizedPath(file).contains('/domain/'));

      for (final file in domainFiles) {
        for (final importUri in _importUris(file)) {
          expect(
            _isForbiddenDomainImport(importUri),
            isFalse,
            reason:
                '${file.path} must keep Domain pure. Forbidden import: $importUri',
          );
        }
      }
    });

    test('presentation layer does not import Supabase or data internals', () {
      final presentationFiles = _dartFilesUnder(
        'lib/features',
      ).where((file) => _normalizedPath(file).contains('/presentation/'));

      for (final file in presentationFiles) {
        for (final importUri in _importUris(file)) {
          expect(
            _isForbiddenPresentationImport(importUri),
            isFalse,
            reason:
                '${file.path} must use use cases/domain APIs, not data internals or Supabase. Forbidden import: $importUri',
          );
        }
      }
    });

    test('audit data wiring is centralized in audit dependencies', () {
      final files = _dartFilesUnder(
        'lib',
      ).where((file) => !_isAuditDependencyImplementationFile(file));

      for (final file in files) {
        final content = file.readAsStringSync();
        for (final importUri in _importUris(file)) {
          expect(
            _isForbiddenAuditDataImport(importUri),
            isFalse,
            reason:
                '${file.path} must use AuditDependencies instead of importing audit data internals. Forbidden import: $importUri',
          );
        }
        expect(
          content,
          isNot(contains('SupabaseAuditLogsRemoteDataSource(')),
          reason:
              '${file.path} must use AuditDependencies instead of creating audit remote data sources.',
        );
        expect(
          content,
          isNot(contains('AuditLogRepositoryImpl(')),
          reason:
              '${file.path} must use AuditDependencies instead of creating audit repositories.',
        );
      }
    });

    test('audit domain use cases rely on failure codes, not message strings', () {
      const paths = [
        'lib/features/audit/domain/usecases/create_audit_log_usecase.dart',
        'lib/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart',
      ];
      const forbiddenSnippets = [
        'Company id is required.',
        'Audit entity id is required.',
        'Audit description is required.',
      ];

      for (final path in paths) {
        final content = _read(path);
        for (final snippet in forbiddenSnippets) {
          expect(
            content,
            isNot(contains(snippet)),
            reason:
                '$path must return typed failure codes and keep user-facing messages in localization.',
          );
        }
      }
    });

    test('customer filter labels are not hardcoded in Dart extensions', () {
      final content = _read(
        'lib/core/localization/app_localizations_extension.dart',
      );

      expect(content, isNot(contains('CustomerFilterLocalizationsX')));
      const forbiddenLabels = [
        'Reactivate',
        'Search customers',
        'All',
        'Active',
        'Inactive',
        'No customers match the current search or status filter.',
        'إعادة تفعيل',
        'ابحث في العملاء',
        'الكل',
        'النشط',
        'غير النشط',
        'لا يوجد عملاء مطابقون للبحث أو فلتر الحالة الحالي.',
      ];

      for (final label in forbiddenLabels) {
        expect(
          content,
          isNot(contains("'$label'")),
          reason:
              'Customer filter labels must live in ARB/generated localization, not Dart extensions.',
        );
        expect(
          content,
          isNot(contains('"$label"')),
          reason:
              'Customer filter labels must live in ARB/generated localization, not Dart extensions.',
        );
      }
    });

    test('company expense category labels are not hardcoded in Dart', () {
      final content = _read(
        'lib/features/company_expenses/presentation/localization/'
        'company_expense_category_localizations_x.dart',
      );

      const forbiddenLabels = [
        'Vehicle maintenance',
        'Spare parts',
        'Tires',
        'Oils and fluids',
        'Licenses and renewals',
        'Office expenses',
        'Rent',
        'Salaries',
        'Admin costs',
        'Fines',
        'Other',
        'صيانة المركبات',
        'قطع الغيار',
        'الإطارات',
        'الزيوت والسوائل',
        'التراخيص والتجديدات',
        'مصروفات المكتب',
        'الإيجار',
        'الرواتب',
        'المصروفات الإدارية',
        'الغرامات',
        'أخرى',
      ];

      for (final label in forbiddenLabels) {
        expect(
          content,
          isNot(contains("'$label'")),
          reason:
              'Company expense category labels must live in ARB/generated localization, not Dart.',
        );
        expect(
          content,
          isNot(contains('"$label"')),
          reason:
              'Company expense category labels must live in ARB/generated localization, not Dart.',
        );
      }
    });

    test('domain tests do not import flutter_test', () {
      final domainTestFiles = _dartFilesUnder(
        'test/features',
      ).where((file) => _normalizedPath(file).contains('/domain/'));

      for (final file in domainTestFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNot(contains('package:flutter_test/flutter_test.dart')),
          reason: '${file.path} must use package:test for pure domain tests.',
        );
      }
    });

    test('new data sources use data constants for database table names', () {
      final dataSourceFiles = _dartFilesUnder('lib/features').where((file) {
        final path = _normalizedPath(file);
        return path.contains('/data/datasources/') &&
            !_allowedDataSourcesWithLocalTableConstants.contains(path);
      });
      final localTablePattern = RegExp(
        r'''^\s*const\s+_\w*Table\w*\s*=\s*['"][^'"]+['"]''',
      );

      for (final file in dataSourceFiles) {
        final content = file.readAsStringSync();
        expect(
          localTablePattern.hasMatch(content),
          isFalse,
          reason:
              '${file.path} must keep database table names in data constants, not local datasource constants.',
        );
      }
    });

    test('new presentation localization code uses ARB-backed localization', () {
      final localizationFiles = _dartFilesUnder('lib/features').where((file) {
        final path = _normalizedPath(file);
        return path.contains('/presentation/localization/') &&
            !_allowedManualPresentationLocalizationFiles.contains(path);
      });
      final manualLanguageBranchPattern = RegExp(
        r'''_isArabic\s*\?\s*['"][^'"]+['"]\s*:\s*['"][^'"]+['"]''',
      );

      for (final file in localizationFiles) {
        final content = file.readAsStringSync();
        expect(
          manualLanguageBranchPattern.hasMatch(content),
          isFalse,
          reason:
              '${file.path} must use ARB/generated localization instead of manual language string branches.',
        );
      }
    });

    test('new features include a matching test directory', () {
      final featureDirectories = Directory('lib/features')
          .listSync()
          .whereType<Directory>()
          .map(_normalizedDirectoryPath)
          .where(
            (path) =>
                !_allowedFeaturesWithoutTests.contains(path.split('/').last),
          );

      for (final featurePath in featureDirectories) {
        final featureName = featurePath.split('/').last;
        final testDirectory = Directory('test/features/$featureName');
        expect(
          testDirectory.existsSync() &&
              _dartFilesUnder(testDirectory.path).isNotEmpty,
          isTrue,
          reason:
              'lib/features/$featureName must have matching tests under test/features/$featureName.',
        );
      }
    });
  });
}

const _allowedDataSourcesWithLocalTableConstants = {
  'lib/features/company_expenses/data/datasources/company_expenses_remote_data_source.dart',
  'lib/features/expenses/data/datasources/trip_expenses_remote_data_source.dart',
  'lib/features/routes/data/datasources/routes_remote_data_source.dart',
  'lib/features/trips/data/datasources/trips_remote_data_source.dart',
};

const _allowedManualPresentationLocalizationFiles = {
  'lib/features/reports/presentation/localization/reports_localizations.dart',
  'lib/features/trips/presentation/localization/trips_localizations_x.dart',
};

const _allowedFeaturesWithoutTests = {'auth', 'fleet'};

String _read(String path) => File(path).readAsStringSync();

Iterable<File> _dartFilesUnder(String path) {
  final directory = Directory(path);
  if (!directory.existsSync()) return const [];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

String _normalizedPath(File file) => file.path.replaceAll('\\', '/');

String _normalizedDirectoryPath(Directory directory) {
  return directory.path.replaceAll('\\', '/');
}

Iterable<String> _importUris(File file) sync* {
  final importPattern = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"]''');
  for (final line in file.readAsLinesSync()) {
    final match = importPattern.firstMatch(line);
    if (match == null) continue;
    yield match.group(2)!;
  }
}

bool _isForbiddenDomainImport(String importUri) {
  return importUri == 'dart:ui' ||
      importUri.startsWith('package:flutter') ||
      importUri.contains('supabase') ||
      importUri.contains('flutter_bloc') ||
      importUri.contains('/data/') ||
      importUri.contains('../data/') ||
      importUri.contains('/presentation/') ||
      importUri.contains('../presentation/') ||
      importUri.contains('/cubit/') ||
      importUri.contains('../cubit/');
}

bool _isForbiddenPresentationImport(String importUri) {
  return importUri.contains('supabase') ||
      importUri.contains('/data/datasources/') ||
      importUri.contains('../data/datasources/') ||
      importUri.contains('/data/models/') ||
      importUri.contains('../data/models/') ||
      importUri.contains('/data/repositories/') ||
      importUri.contains('../data/repositories/') ||
      importUri.contains('/data/constants/') ||
      importUri.contains('../data/constants/');
}

bool _isAuditDependencyImplementationFile(File file) {
  final path = _normalizedPath(file);
  return path.endsWith('/features/audit/di/audit_dependencies.dart') ||
      path.endsWith(
        '/features/audit/data/datasources/audit_logs_remote_data_source.dart',
      ) ||
      path.endsWith(
        '/features/audit/data/repositories/audit_log_repository_impl.dart',
      );
}

bool _isForbiddenAuditDataImport(String importUri) {
  return importUri.contains('features/audit/data/') ||
      importUri.contains('../audit/data/') ||
      importUri.contains('../../audit/data/') ||
      importUri.contains('../../../audit/data/') ||
      importUri.contains('../../../../audit/data/');
}
