import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, StorageException;

import '../../../../core/data/utils/uuid_v4.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_brand_logo_file.dart';
import '../../domain/entities/company_brand_profile.dart';
import '../../domain/failures/company_branding_failure_codes.dart';
import '../../domain/policies/company_brand_logo_policy.dart';
import '../../domain/repositories/company_branding_repository.dart';
import '../constants/company_branding_constants.dart';
import '../constants/company_rpc_constants.dart';
import '../datasources/company_branding_remote_data_source.dart';
import 'company_branding_failure_mapper.dart';

final class CompanyBrandingRepositoryImpl implements CompanyBrandingRepository {
  final CompanyBrandingRemoteDataSource _source;
  final CompanyBrandingFailureMapper _mapper;

  const CompanyBrandingRepositoryImpl(
    this._source, {
    CompanyBrandingFailureMapper mapper = const CompanyBrandingFailureMapper(),
  }) : _mapper = mapper;

  @override
  Future<Result<CompanyBrandProfile>> getProfile(String companyId) =>
      _guard(() async => (await _source.loadProfile(companyId)).toEntity());

  @override
  Future<Result<CompanyBrandProfile>> updateProfile({
    required String companyId,
    required DateTime expectedUpdatedAt,
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
    String? address,
    String? taxRegistrationNumber,
  }) => _guard(() async {
    final result = await _source.updateProfile({
      CompanyBrandingConstants.companyIdArg: companyId,
      CompanyBrandingConstants.expectedUpdatedAtArg: expectedUpdatedAt
          .toUtc()
          .toIso8601String(),
      CompanyRpcConstants.companyName: name,
      CompanyRpcConstants.businessType: businessType,
      CompanyRpcConstants.phone: phone,
      CompanyRpcConstants.email: email,
      CompanyRpcConstants.country: country,
      CompanyRpcConstants.city: city,
      CompanyBrandingConstants.addressArg: address,
      CompanyBrandingConstants.registrationArg: taxRegistrationNumber,
    });
    return result.toEntity();
  });

  @override
  Future<Result<CompanyBrandProfile>> removeLogo({
    required String companyId,
    required String? expectedLogoPath,
  }) => _guard(() async {
    final result = await _source.setLogo(
      companyId: companyId,
      expectedLogoPath: expectedLogoPath,
      newLogoPath: null,
    );
    return result.toEntity();
  });

  @override
  Future<Result<Uint8List>> downloadLogo({
    required String companyId,
    required String storagePath,
  }) => _guard(() {
    final prefix =
        '${CompanyBrandingConstants.storageRoot}/$companyId/'
        '${CompanyBrandingConstants.storageLogoFolder}/';
    if (!storagePath.startsWith(prefix)) {
      throw const FormatException('Invalid company branding object key');
    }
    return _source.download(storagePath);
  });

  @override
  Future<Result<CompanyBrandProfile>> updateLogo({
    required String companyId,
    required String? expectedLogoPath,
    required CompanyBrandLogoFile logo,
  }) async {
    final extension = CompanyBrandLogoPolicy.extensionFor(logo);
    if (extension == null) {
      return const FailureResult(
        ValidationFailure(code: CompanyBrandingFailureCodes.imageUnsupported),
      );
    }
    final operationId = newUuidV4();
    final path =
        '${CompanyBrandingConstants.storageRoot}/$companyId/'
        '${CompanyBrandingConstants.storageLogoFolder}/'
        '$operationId.$extension';
    final contentType = switch (extension) {
      'png' => CompanyBrandingConstants.mimePng,
      'webp' => CompanyBrandingConstants.mimeWebp,
      _ => CompanyBrandingConstants.mimeJpeg,
    };

    try {
      await _source.reserveUpload(
        companyId: companyId,
        operationId: operationId,
        storagePath: path,
      );
    } on PostgrestException catch (error) {
      return FailureResult(_mapper.fromDatabase(error));
    } on AuthException catch (error) {
      return FailureResult(_mapper.fromAuth(error));
    } catch (error) {
      return FailureResult(_mapper.fromUnexpected(error));
    }

    try {
      await _source.upload(
        path: path,
        bytes: logo.bytes,
        contentType: contentType,
      );
    } on StorageException catch (error) {
      final pending = await _compensate(companyId, operationId, path);
      return FailureResult(pending ?? _mapper.fromStorage(error));
    } catch (error) {
      final pending = await _compensate(companyId, operationId, path);
      return FailureResult(pending ?? _mapper.fromUnexpected(error));
    }

    try {
      final result = await _source.setLogo(
        companyId: companyId,
        expectedLogoPath: expectedLogoPath,
        newLogoPath: path,
      );
      return Success(result.toEntity());
    } on PostgrestException catch (error) {
      // Only a deterministic business denial may safely roll back uploaded
      // bytes. An ambiguous network outcome could already have committed the
      // logo; retain its immutable object and surface recovery explicitly.
      if (const ['P3510', 'P3511', 'P3512', 'P3513'].contains(error.code)) {
        final pending = await _compensate(companyId, operationId, path);
        return FailureResult(pending ?? _mapper.fromDatabase(error));
      }
      return _reconcileUnknownLogoWrite(companyId, path);
    } catch (_) {
      return _reconcileUnknownLogoWrite(companyId, path);
    }
  }

  /// A transport failure can happen AFTER the logo switch commits.
  /// Never delete the uploaded bytes on an unknown outcome: invoices could
  /// already have captured this exact immutable asset.
  Future<Result<CompanyBrandProfile>> _reconcileUnknownLogoWrite(
    String companyId,
    String uploadedPath,
  ) async {
    try {
      final current = await _source.loadProfile(companyId);
      if (current.logoPath == uploadedPath) {
        return Success(current.toEntity());
      }
    } catch (_) {
      // A read failure cannot prove the mutation was rolled back.
    }
    return const FailureResult(
      ServerFailure(code: CompanyBrandingFailureCodes.uploadCompletionUnknown),
    );
  }

  Future<ServerFailure?> _compensate(
    String companyId,
    String operationId,
    String path,
  ) async {
    var failed = false;
    try {
      await _source.remove(path);
    } catch (_) {
      failed = true;
    }
    try {
      await _source.releaseUpload(
        companyId: companyId,
        operationId: operationId,
      );
    } catch (_) {
      failed = true;
    }
    return failed
        ? const ServerFailure(
            code: CompanyBrandingFailureCodes.uploadCleanupPending,
          )
        : null;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Success(await task());
    } on AuthException catch (error) {
      return FailureResult(_mapper.fromAuth(error));
    } on PostgrestException catch (error) {
      return FailureResult(_mapper.fromDatabase(error));
    } on StorageException catch (error) {
      return FailureResult(_mapper.fromStorage(error));
    } catch (error) {
      return FailureResult(_mapper.fromUnexpected(error));
    }
  }
}
