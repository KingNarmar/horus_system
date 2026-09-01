import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/company_role.dart';
import '../constants/company_invitation_rpc.dart';

abstract class CompanyMembershipRemoteDataSource {
  Future<void> changeRole({
    required String companyId,
    required String membershipId,
    required CompanyRole newRole,
  });

  Future<void> deactivate({
    required String companyId,
    required String membershipId,
  });

  Future<void> reactivate({
    required String companyId,
    required String membershipId,
  });

  Future<void> grantOwnership({
    required String companyId,
    required String membershipId,
  });

  Future<void> transferOwnership({
    required String companyId,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  });
}

class SupabaseCompanyMembershipRemoteDataSource
    implements CompanyMembershipRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyMembershipRemoteDataSource(this._client);

  @override
  Future<void> changeRole({
    required String companyId,
    required String membershipId,
    required CompanyRole newRole,
  }) async {
    await _client.rpc(
      CompanyMembershipRpc.changeRole,
      params: {
        CompanyMembershipRpc.companyIdParam: companyId,
        CompanyMembershipRpc.membershipIdParam: membershipId,
        CompanyMembershipRpc.newRoleParam: newRole.value,
      },
    );
  }

  @override
  Future<void> deactivate({
    required String companyId,
    required String membershipId,
  }) async {
    await _client.rpc(
      CompanyMembershipRpc.deactivate,
      params: {
        CompanyMembershipRpc.companyIdParam: companyId,
        CompanyMembershipRpc.membershipIdParam: membershipId,
      },
    );
  }

  @override
  Future<void> reactivate({
    required String companyId,
    required String membershipId,
  }) async {
    await _client.rpc(
      CompanyMembershipRpc.reactivate,
      params: {
        CompanyMembershipRpc.companyIdParam: companyId,
        CompanyMembershipRpc.membershipIdParam: membershipId,
      },
    );
  }

  @override
  Future<void> grantOwnership({
    required String companyId,
    required String membershipId,
  }) async {
    await _client.rpc(
      CompanyMembershipRpc.grantOwnership,
      params: {
        CompanyMembershipRpc.companyIdParam: companyId,
        CompanyMembershipRpc.membershipIdParam: membershipId,
      },
    );
  }

  @override
  Future<void> transferOwnership({
    required String companyId,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  }) async {
    await _client.rpc(
      CompanyMembershipRpc.transferOwnership,
      params: {
        CompanyMembershipRpc.companyIdParam: companyId,
        CompanyMembershipRpc.targetMembershipIdParam: targetMembershipId,
        CompanyMembershipRpc.sourceNewRoleParam: sourceNewRole.value,
      },
    );
  }
}
