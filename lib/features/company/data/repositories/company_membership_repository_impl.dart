import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/repositories/company_membership_repository.dart';
import '../datasources/company_membership_remote_data_source.dart';
import 'company_command_failure_mapper.dart';

class CompanyMembershipRepositoryImpl implements CompanyMembershipRepository {
  final CompanyMembershipRemoteDataSource _remoteDataSource;

  const CompanyMembershipRepositoryImpl({
    required CompanyMembershipRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  static const _failureMapper = CompanyCommandFailureMapper();

  @override
  Future<Result<void>> changeRole({
    required String companyId,
    required String membershipId,
    required CompanyRole newRole,
  }) {
    return _guard(
      () => _remoteDataSource.changeRole(
        companyId: companyId,
        membershipId: membershipId,
        newRole: newRole,
      ),
    );
  }

  @override
  Future<Result<void>> deactivate({
    required String companyId,
    required String membershipId,
  }) {
    return _guard(
      () => _remoteDataSource.deactivate(
        companyId: companyId,
        membershipId: membershipId,
      ),
    );
  }

  @override
  Future<Result<void>> reactivate({
    required String companyId,
    required String membershipId,
  }) {
    return _guard(
      () => _remoteDataSource.reactivate(
        companyId: companyId,
        membershipId: membershipId,
      ),
    );
  }

  @override
  Future<Result<void>> grantOwnership({
    required String companyId,
    required String membershipId,
  }) {
    return _guard(
      () => _remoteDataSource.grantOwnership(
        companyId: companyId,
        membershipId: membershipId,
      ),
    );
  }

  @override
  Future<Result<void>> transferOwnership({
    required String companyId,
    required String targetMembershipId,
    required CompanyRole sourceNewRole,
  }) {
    return _guard(
      () => _remoteDataSource.transferOwnership(
        companyId: companyId,
        targetMembershipId: targetMembershipId,
        sourceNewRole: sourceNewRole,
      ),
    );
  }

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Success<void>(null);
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
