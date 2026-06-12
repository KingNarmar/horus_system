import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_db_fields.dart';

abstract class CompanyRemoteDataSource {
  Future<CompanyModel> createCompany({
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  });

  Future<List<CompanyModel>> getMyCompanies();
}

class SupabaseCompanyRemoteDataSource implements CompanyRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyRemoteDataSource(this._client);

  @override
  Future<CompanyModel> createCompany({
    required String name,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw AuthException('User must be authenticated to create a company.');
    }

    final companyId = _generateUuidV4();

    final companyPayload = _removeNullValues({
      DbCommonFields.id: companyId,
      CompanyDbFields.name: name,
      'business_type': businessType,
      'phone': phone,
      'email': email,
      'country': country,
      'city': city,
      'created_by': userId,
      'updated_by': userId,
    });

    await _client.from(CompanyDbFields.companiesTable).insert(companyPayload);

    await _client.from(CompanyDbFields.companyUsersTable).insert({
      DbCommonFields.companyId: companyId,
      CompanyDbFields.userId: userId,
      CompanyDbFields.role: 'owner',
      'created_by': userId,
      'updated_by': userId,
    });

    return CompanyModel(
      id: companyId,
      name: name,
      businessType: businessType,
      phone: phone,
      email: email,
      country: country,
      city: city,
    );
  }

  @override
  Future<List<CompanyModel>> getMyCompanies() async {
    final response = await _client
        .from(CompanyDbFields.companiesTable)
        .select(
          'id,name,business_type,phone,email,country,city,logo_url,is_active',
        )
        .eq(DbCommonFields.isActive, true)
        .order(DbCommonFields.createdAt);

    return response
        .map((item) => CompanyModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _removeNullValues(Map<String, dynamic> values) {
    return Map.fromEntries(
      values.entries.where((entry) => entry.value != null),
    );
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    final chars = bytes.map(hex).join();

    return '${chars.substring(0, 8)}-'
        '${chars.substring(8, 12)}-'
        '${chars.substring(12, 16)}-'
        '${chars.substring(16, 20)}-'
        '${chars.substring(20)}';
  }
}
