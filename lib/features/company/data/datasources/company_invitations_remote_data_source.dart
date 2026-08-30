import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/company_role.dart';
import '../constants/company_invitation_rpc.dart';
import '../models/company_invitation_delivery_preparation_model.dart';
import '../models/company_invitation_model.dart';
import '../models/company_invitation_preview_model.dart';

abstract class CompanyInvitationsRemoteDataSource {
  Future<List<CompanyInvitationModel>> getInvitations(String companyId);

  Future<CompanyInvitationDeliveryPreparationModel> prepareInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
    required String postgresByteaTokenHash,
  });

  Future<CompanyInvitationDeliveryPreparationModel> prepareResend({
    required String companyId,
    required String invitationId,
    required String postgresByteaTokenHash,
  });

  Future<void> confirmDelivery({
    required String companyId,
    required String invitationId,
    required String deliveryAttemptId,
  });

  Future<void> revokeInvitation({
    required String companyId,
    required String invitationId,
  });

  Future<CompanyInvitationPreviewModel> getPreview(
    String postgresByteaTokenHash,
  );

  Future<String> acceptInvitation(String postgresByteaTokenHash);
}

class SupabaseCompanyInvitationsRemoteDataSource
    implements CompanyInvitationsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCompanyInvitationsRemoteDataSource(this._client);

  @override
  Future<List<CompanyInvitationModel>> getInvitations(String companyId) async {
    final response = await _client.rpc(
      CompanyInvitationRpc.list,
      params: {CompanyInvitationRpc.companyIdParam: companyId},
    );

    return _rows(response)
        .map(CompanyInvitationModel.fromRpcMap)
        .toList(growable: false);
  }

  @override
  Future<CompanyInvitationDeliveryPreparationModel> prepareInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
    required String postgresByteaTokenHash,
  }) async {
    final response = await _client.rpc(
      CompanyInvitationRpc.prepare,
      params: {
        CompanyInvitationRpc.companyIdParam: companyId,
        CompanyInvitationRpc.emailParam: email,
        CompanyInvitationRpc.roleParam: role.value,
        CompanyInvitationRpc.tokenHashParam: postgresByteaTokenHash,
      },
    );

    return CompanyInvitationDeliveryPreparationModel.fromRpcMap(
      _singleRow(response),
    );
  }

  @override
  Future<CompanyInvitationDeliveryPreparationModel> prepareResend({
    required String companyId,
    required String invitationId,
    required String postgresByteaTokenHash,
  }) async {
    final response = await _client.rpc(
      CompanyInvitationRpc.prepareResend,
      params: {
        CompanyInvitationRpc.companyIdParam: companyId,
        CompanyInvitationRpc.invitationIdParam: invitationId,
        CompanyInvitationRpc.tokenHashParam: postgresByteaTokenHash,
      },
    );

    return CompanyInvitationDeliveryPreparationModel.fromRpcMap(
      _singleRow(response),
    );
  }

  @override
  Future<void> confirmDelivery({
    required String companyId,
    required String invitationId,
    required String deliveryAttemptId,
  }) async {
    await _client.rpc(
      CompanyInvitationRpc.confirmDelivery,
      params: {
        CompanyInvitationRpc.companyIdParam: companyId,
        CompanyInvitationRpc.invitationIdParam: invitationId,
        CompanyInvitationRpc.deliveryAttemptIdParam: deliveryAttemptId,
      },
    );
  }

  @override
  Future<void> revokeInvitation({
    required String companyId,
    required String invitationId,
  }) async {
    await _client.rpc(
      CompanyInvitationRpc.revoke,
      params: {
        CompanyInvitationRpc.companyIdParam: companyId,
        CompanyInvitationRpc.invitationIdParam: invitationId,
      },
    );
  }

  @override
  Future<CompanyInvitationPreviewModel> getPreview(
    String postgresByteaTokenHash,
  ) async {
    final response = await _client.rpc(
      CompanyInvitationRpc.preview,
      params: {
        CompanyInvitationRpc.tokenHashParam: postgresByteaTokenHash,
      },
    );

    return CompanyInvitationPreviewModel.fromRpcMap(_singleRow(response));
  }

  @override
  Future<String> acceptInvitation(String postgresByteaTokenHash) async {
    final response = await _client.rpc(
      CompanyInvitationRpc.accept,
      params: {
        CompanyInvitationRpc.tokenHashParam: postgresByteaTokenHash,
      },
    );

    return _singleRow(response)[CompanyInvitationRpc.companyId] as String;
  }

  static List<Map<String, dynamic>> _rows(Object? response) {
    if (response is! List) {
      throw const FormatException('Expected an RPC row list.');
    }

    return response
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  static Map<String, dynamic> _singleRow(Object? response) {
    final rows = _rows(response);
    if (rows.length != 1) {
      throw const FormatException('Expected exactly one RPC row.');
    }
    return rows.single;
  }
}
