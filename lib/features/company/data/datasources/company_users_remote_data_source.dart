import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_user_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/constants/user_profile_db_fields.dart';
import '../constants/company_db_fields.dart';

abstract class CompanyUsersRemoteDataSource {
  Future<List<CompanyUserModel>> getCompanyUsers({required String companyId});
}

class SupabaseCompanyUsersRemoteDataSource
    implements CompanyUsersRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyUsersRemoteDataSource(this._client);

  @override
  Future<List<CompanyUserModel>> getCompanyUsers({
    required String companyId,
  }) async {
    final companyUsersResponse = await _client
        .from(CompanyDbFields.companyUsersTable)
        .select('id,company_id,user_id,role,is_active')
        .eq(DbCommonFields.companyId, companyId)
        .order(DbCommonFields.createdAt);

    final companyUserMaps = companyUsersResponse
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (companyUserMaps.isEmpty) {
      return const [];
    }

    final userIds = companyUserMaps
        .map((item) => item[CompanyDbFields.userId] as String)
        .toSet()
        .toList();

    final profilesByUserId = await _loadProfilesByUserId(userIds);

    return companyUserMaps.map((companyUserMap) {
      final userId = companyUserMap[CompanyDbFields.userId] as String;

      return CompanyUserModel.fromMaps(
        companyUserMap: companyUserMap,
        userProfileMap: profilesByUserId[userId],
      );
    }).toList();
  }

  Future<Map<String, Map<String, dynamic>>> _loadProfilesByUserId(
    List<String> userIds,
  ) async {
    try {
      final userProfilesResponse = await _client
          .from(UserProfileDbFields.tableName)
          .select('id,full_name,phone')
          .inFilter(DbCommonFields.id, userIds);

      final profilesByUserId = <String, Map<String, dynamic>>{};

      for (final item in userProfilesResponse) {
        final profileMap = Map<String, dynamic>.from(item);
        final userId = profileMap[DbCommonFields.id] as String?;

        if (userId != null) {
          profilesByUserId[userId] = profileMap;
        }
      }

      return profilesByUserId;
    } on PostgrestException {
      return const {};
    }
  }
}
