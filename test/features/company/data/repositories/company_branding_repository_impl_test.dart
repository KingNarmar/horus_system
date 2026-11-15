import 'dart:typed_data';

import 'package:horus_system/features/company/data/datasources/company_branding_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_brand_profile_model.dart';
import 'package:horus_system/features/company/data/repositories/company_branding_repository_impl.dart';
import 'package:horus_system/features/company/domain/entities/company_brand_logo_file.dart';
import 'package:horus_system/features/company/domain/failures/company_branding_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  const companyId = '11111111-1111-1111-1111-111111111111';
  CompanyBrandLogoFile validLogo() => CompanyBrandLogoFile(
    fileName: 'logo.png',
    bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
  );

  test(
    'uploads only after reservation then commits immutable company key',
    () async {
      final source = _FakeBrandingSource();
      final repo = CompanyBrandingRepositoryImpl(source);
      final result = await repo.updateLogo(
        companyId: companyId,
        expectedLogoPath: null,
        logo: validLogo(),
      );

      expect(result.isSuccess, isTrue);
      expect(source.events, ['reserve', 'upload', 'setLogo']);
      expect(
        source.lastUploadPath,
        matches(
          RegExp(
            r'^companies/11111111-1111-1111-1111-111111111111/logos/'
            r'[0-9a-f-]{36}[.]png$',
          ),
        ),
      );
      expect(source.lastContentType, 'image/png');
      expect(result.dataOrNull?.logoPath, source.lastUploadPath);
      expect(source.removedPaths, isEmpty);
    },
  );

  test('Storage failure compensates both bytes and upload lease', () async {
    final source = _FakeBrandingSource()..uploadError = StateError('offline');
    final result = await CompanyBrandingRepositoryImpl(source).updateLogo(
      companyId: companyId,
      expectedLogoPath: null,
      logo: validLogo(),
    );
    expect(result.isFailure, isTrue);
    expect(source.events, ['reserve', 'upload', 'remove', 'release']);
    expect(source.removedPaths, [source.lastUploadPath]);
  });

  test('deterministic conflict rolls back orphan logo upload', () async {
    final source = _FakeBrandingSource()
      ..setError = const PostgrestException(
        message: 'company_branding_logo_conflict',
        code: 'P3512',
      );
    final result = await CompanyBrandingRepositoryImpl(source).updateLogo(
      companyId: companyId,
      expectedLogoPath: null,
      logo: validLogo(),
    );
    expect(
      result.failureOrNull?.code,
      CompanyBrandingFailureCodes.profileConflict,
    );
    expect(source.events, [
      'reserve',
      'upload',
      'setLogo',
      'remove',
      'release',
    ]);
  });

  test(
    'unknown HTTP result is reconciled if server already committed',
    () async {
      final source = _FakeBrandingSource()
        ..commitBeforeSetError = true
        ..setError = StateError('response lost');
      final result = await CompanyBrandingRepositoryImpl(source).updateLogo(
        companyId: companyId,
        expectedLogoPath: null,
        logo: validLogo(),
      );
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.logoPath, source.lastUploadPath);
      expect(source.events, ['reserve', 'upload', 'setLogo', 'loadProfile']);
      expect(source.removedPaths, isEmpty);
    },
  );

  test('unresolved write never deletes possibly issued logo bytes', () async {
    final source = _FakeBrandingSource()
      ..setError = StateError('connection lost')
      ..loadError = StateError('cannot verify');
    final result = await CompanyBrandingRepositoryImpl(source).updateLogo(
      companyId: companyId,
      expectedLogoPath: null,
      logo: validLogo(),
    );
    expect(
      result.failureOrNull?.code,
      CompanyBrandingFailureCodes.uploadCompletionUnknown,
    );
    expect(source.events, ['reserve', 'upload', 'setLogo', 'loadProfile']);
    expect(source.removedPaths, isEmpty);
  });

  test('failed compensation remains a typed, visible failure', () async {
    final source = _FakeBrandingSource()
      ..uploadError = StateError('upload failed')
      ..removeError = StateError('cleanup failed');
    final result = await CompanyBrandingRepositoryImpl(source).updateLogo(
      companyId: companyId,
      expectedLogoPath: null,
      logo: validLogo(),
    );
    expect(
      result.failureOrNull?.code,
      CompanyBrandingFailureCodes.uploadCleanupPending,
    );
    expect(source.events, ['reserve', 'upload', 'remove', 'release']);
  });

  test('foreign Storage path is rejected before download', () async {
    final source = _FakeBrandingSource();
    final result = await CompanyBrandingRepositoryImpl(source).downloadLogo(
      companyId: companyId,
      storagePath: 'companies/22222222-2222-2222-2222-222222222222/logos/a.png',
    );
    expect(result.isFailure, isTrue);
    expect(source.events, isEmpty);
  });
}

class _FakeBrandingSource implements CompanyBrandingRemoteDataSource {
  final events = <String>[];
  final removedPaths = <String>[];
  Object? uploadError;
  Object? setError;
  Object? removeError;
  Object? loadError;
  bool commitBeforeSetError = false;
  String? lastUploadPath;
  String? lastContentType;
  String? currentLogoPath;

  CompanyBrandProfileModel _profile() => CompanyBrandProfileModel(
    companyId: '11111111-1111-1111-1111-111111111111',
    name: 'Transport',
    updatedAt: DateTime.utc(2026, 11, 15),
    logoPath: currentLogoPath,
  );

  @override
  Future<CompanyBrandProfileModel> loadProfile(String companyId) async {
    events.add('loadProfile');
    if (loadError != null) throw loadError!;
    return _profile();
  }

  @override
  Future<CompanyBrandProfileModel> updateProfile(
    Map<String, Object?> payload,
  ) async => _profile();

  @override
  Future<CompanyBrandProfileModel> setLogo({
    required String companyId,
    required String? expectedLogoPath,
    required String? newLogoPath,
  }) async {
    events.add('setLogo');
    if (setError != null) {
      if (commitBeforeSetError) currentLogoPath = newLogoPath;
      throw setError!;
    }
    currentLogoPath = newLogoPath;
    return _profile();
  }

  @override
  Future<void> reserveUpload({
    required String companyId,
    required String operationId,
    required String storagePath,
  }) async {
    events.add('reserve');
    expect(storagePath.contains('/logos/$operationId.'), isTrue);
  }

  @override
  Future<void> releaseUpload({
    required String companyId,
    required String operationId,
  }) async {
    events.add('release');
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    events.add('upload');
    lastUploadPath = path;
    lastContentType = contentType;
    if (uploadError != null) throw uploadError!;
  }

  @override
  Future<void> remove(String path) async {
    events.add('remove');
    removedPaths.add(path);
    if (removeError != null) throw removeError!;
  }

  @override
  Future<Uint8List> download(String path) async {
    events.add('download');
    return Uint8List(0);
  }
}
