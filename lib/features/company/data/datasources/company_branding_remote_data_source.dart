import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_branding_constants.dart';
import '../constants/company_db_fields.dart';
import '../constants/company_rpc_constants.dart';
import '../models/company_brand_profile_model.dart';

abstract class CompanyBrandingRemoteDataSource {
  Future<CompanyBrandProfileModel> loadProfile(String companyId);
  Future<CompanyBrandProfileModel> updateProfile(Map<String, Object?> payload);
  Future<CompanyBrandProfileModel> setLogo({
    required String companyId,
    required String? expectedLogoPath,
    required String? newLogoPath,
  });
  Future<void> reserveUpload({
    required String companyId,
    required String operationId,
    required String storagePath,
  });
  Future<void> releaseUpload({
    required String companyId,
    required String operationId,
  });
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });
  Future<void> remove(String path);
  Future<Uint8List> download(String path);
}

final class SupabaseCompanyBrandingRemoteDataSource
    implements CompanyBrandingRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyBrandingRemoteDataSource(this._client);

  @override
  Future<CompanyBrandProfileModel> loadProfile(String companyId) async {
    final response = await _client
        .from(CompanyDbFields.companiesTable)
        .select(_companyBrandProfileProjection)
        .eq(DbCommonFields.id, companyId)
        .single();
    return CompanyBrandProfileModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<CompanyBrandProfileModel> updateProfile(
    Map<String, Object?> payload,
  ) async {
    final response = await _client
        .rpc(CompanyBrandingConstants.updateProfileRpc, params: payload)
        .single();
    return CompanyBrandProfileModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<CompanyBrandProfileModel> setLogo({
    required String companyId,
    required String? expectedLogoPath,
    required String? newLogoPath,
  }) async {
    final response = await _client
        .rpc(
          CompanyBrandingConstants.setLogoRpc,
          params: {
            CompanyBrandingConstants.companyIdArg: companyId,
            CompanyBrandingConstants.expectedLogoArg: expectedLogoPath,
            CompanyBrandingConstants.newLogoArg: newLogoPath,
          },
        )
        .single();
    return CompanyBrandProfileModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<void> reserveUpload({
    required String companyId,
    required String operationId,
    required String storagePath,
  }) async {
    await _client.rpc(
      CompanyBrandingConstants.reserveUploadRpc,
      params: {
        CompanyBrandingConstants.companyIdArg: companyId,
        CompanyBrandingConstants.operationIdArg: operationId,
        CompanyBrandingConstants.pathArg: storagePath,
      },
    );
  }

  @override
  Future<void> releaseUpload({
    required String companyId,
    required String operationId,
  }) async {
    await _client.rpc(
      CompanyBrandingConstants.releaseUploadRpc,
      params: {
        CompanyBrandingConstants.companyIdArg: companyId,
        CompanyBrandingConstants.operationIdArg: operationId,
      },
    );
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from(CompanyBrandingConstants.storageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

  @override
  Future<void> remove(String path) async {
    await _client.storage.from(CompanyBrandingConstants.storageBucket).remove([
      path,
    ]);
  }

  @override
  Future<Uint8List> download(String path) => _client.storage
      .from(CompanyBrandingConstants.storageBucket)
      .download(path);
}

final _companyBrandProfileProjection = <String>[
  DbCommonFields.id,
  DbCommonFields.updatedAt,
  CompanyDbFields.name,
  CompanyDbFields.businessType,
  CompanyDbFields.phone,
  CompanyDbFields.email,
  CompanyDbFields.country,
  CompanyDbFields.city,
  CompanyDbFields.address,
  CompanyDbFields.taxRegistrationNumber,
  CompanyDbFields.logoUrl,
].join(',');
