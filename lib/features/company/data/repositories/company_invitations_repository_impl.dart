import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_invitation_preview.dart';
import '../../domain/entities/company_role.dart';
import '../../domain/repositories/company_invitations_repository.dart';
import '../datasources/company_invitation_delivery_remote_data_source.dart';
import '../datasources/company_invitations_remote_data_source.dart';
import '../services/company_invitation_token_codec.dart';
import 'company_command_failure_mapper.dart';

class CompanyInvitationsRepositoryImpl implements CompanyInvitationsRepository {
  final CompanyInvitationsRemoteDataSource _remoteDataSource;
  final CompanyInvitationDeliveryRemoteDataSource _deliveryRemoteDataSource;
  final CompanyInvitationTokenCodec _tokenCodec;

  const CompanyInvitationsRepositoryImpl({
    required CompanyInvitationsRemoteDataSource remoteDataSource,
    required CompanyInvitationDeliveryRemoteDataSource deliveryRemoteDataSource,
    required CompanyInvitationTokenCodec tokenCodec,
  }) : _remoteDataSource = remoteDataSource,
       _deliveryRemoteDataSource = deliveryRemoteDataSource,
       _tokenCodec = tokenCodec;

  static const _failureMapper = CompanyCommandFailureMapper();

  @override
  Future<Result<List<CompanyInvitation>>> getInvitations(String companyId) {
    return _guard(
      () async => (await _remoteDataSource.getInvitations(
        companyId,
      )).map((model) => model.toEntity()).toList(growable: false),
    );
  }

  @override
  Future<Result<void>> sendInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
  }) {
    return _guard(
      () => _deliveryRemoteDataSource.sendInvitation(
        companyId: companyId,
        email: email,
        role: role,
      ),
    );
  }

  @override
  Future<Result<void>> resendInvitation({
    required String companyId,
    required String invitationId,
  }) {
    return _guard(
      () => _deliveryRemoteDataSource.resendInvitation(
        companyId: companyId,
        invitationId: invitationId,
      ),
    );
  }

  @override
  Future<Result<void>> revokeInvitation({
    required String companyId,
    required String invitationId,
  }) {
    return _guard(
      () => _remoteDataSource.revokeInvitation(
        companyId: companyId,
        invitationId: invitationId,
      ),
    );
  }

  @override
  Future<Result<CompanyInvitationPreview>> getInvitationPreview(String token) {
    return _guard(
      () async => (await _remoteDataSource.getPreview(
        _tokenCodec.hashForPostgres(token),
      )).toEntity(),
    );
  }

  @override
  Future<Result<String>> acceptInvitation(String token) {
    return _guard(
      () => _remoteDataSource.acceptInvitation(
        _tokenCodec.hashForPostgres(token),
      ),
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success<T>(await action());
    } on CompanyInvitationDeliveryException catch (error) {
      return FailureResult(_failureMapper.fromDelivery(error));
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
