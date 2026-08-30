import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/company_role.dart';
import '../../domain/failures/company_failure_codes.dart';

abstract class CompanyInvitationDeliveryRemoteDataSource {
  Future<void> sendInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
  });

  Future<void> resendInvitation({
    required String companyId,
    required String invitationId,
  });
}

class CompanyInvitationDeliveryException implements Exception {
  final String code;

  const CompanyInvitationDeliveryException(this.code);
}

class SupabaseCompanyInvitationDeliveryRemoteDataSource
    implements CompanyInvitationDeliveryRemoteDataSource {
  static const _functionName = 'send-company-invitation';
  static const _sendAction = 'send';
  static const _resendAction = 'resend';

  final SupabaseClient _client;

  const SupabaseCompanyInvitationDeliveryRemoteDataSource(this._client);

  @override
  Future<void> sendInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
  }) {
    return _invoke({
      'action': _sendAction,
      'company_id': companyId,
      'email': email,
      'role': role.value,
    });
  }

  @override
  Future<void> resendInvitation({
    required String companyId,
    required String invitationId,
  }) {
    return _invoke({
      'action': _resendAction,
      'company_id': companyId,
      'invitation_id': invitationId,
    });
  }

  Future<void> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: body,
      );
      final data = response.data;

      if (data is Map && data['ok'] == true) {
        return;
      }

      throw CompanyInvitationDeliveryException(
        _semanticCode(data) ??
            CompanyFailureCodes.invitationDeliveryConfirmationUnknown,
      );
    } on CompanyInvitationDeliveryException {
      rethrow;
    } on FunctionException catch (error) {
      throw CompanyInvitationDeliveryException(
        _semanticCode(error.details) ??
            CompanyFailureCodes.invitationDeliveryConfirmationUnknown,
      );
    }
  }

  static String? _semanticCode(Object? payload) {
    if (payload is! Map) return null;
    final value = payload['code'];
    if (value is! String || !value.startsWith('company_')) return null;
    return value;
  }
}
