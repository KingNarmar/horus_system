import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/company/data/mappers/company_invitation_status_model_mapper.dart';
import 'package:horus_system/features/company/data/models/company_invitation_model.dart';
import 'package:horus_system/features/company/data/models/company_invitation_preview_model.dart';
import 'package:horus_system/features/company/data/repositories/company_command_failure_mapper.dart';
import 'package:horus_system/features/company/data/services/company_invitation_token_codec.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_status.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyInvitationStatusModelMapper', () {
    test('maps every supported database status', () {
      expect(
        CompanyInvitationStatusModelMapper.fromDatabaseValue('pending'),
        CompanyInvitationStatus.pending,
      );
      expect(
        CompanyInvitationStatusModelMapper.fromDatabaseValue('accepted'),
        CompanyInvitationStatus.accepted,
      );
      expect(
        CompanyInvitationStatusModelMapper.fromDatabaseValue('expired'),
        CompanyInvitationStatus.expired,
      );
      expect(
        CompanyInvitationStatusModelMapper.fromDatabaseValue('revoked'),
        CompanyInvitationStatus.revoked,
      );
    });

    test('rejects unknown database status instead of hiding schema drift', () {
      expect(
        () => CompanyInvitationStatusModelMapper.fromDatabaseValue('unknown'),
        throwsFormatException,
      );
    });
  });

  test('CompanyInvitationModel maps RPC row into typed entity', () {
    final model = CompanyInvitationModel.fromRpcMap({
      'invitation_id': 'invitation-1',
      'company_id': 'company-1',
      'email_normalized': 'user@example.com',
      'invitation_role': 'viewer',
      'effective_status': 'pending',
      'expires_at': '2026-09-01T12:00:00Z',
      'last_sent_at': '2026-08-30T12:00:00Z',
      'send_count': 2,
      'created_at': '2026-08-30T11:00:00Z',
      'accepted_at': null,
      'revoked_at': null,
    });

    final entity = model.toEntity();
    expect(entity.id, 'invitation-1');
    expect(entity.companyId, 'company-1');
    expect(entity.email, 'user@example.com');
    expect(entity.role, CompanyRole.viewer);
    expect(entity.status, CompanyInvitationStatus.pending);
    expect(entity.sendCount, 2);
    expect(entity.lastSentAt, DateTime.parse('2026-08-30T12:00:00Z'));
  });

  test('CompanyInvitationModel rejects unknown role schema drift', () {
    expect(
      () => CompanyInvitationModel.fromRpcMap({
        'invitation_id': 'invitation-1',
        'company_id': 'company-1',
        'email_normalized': 'user@example.com',
        'invitation_role': 'future_role',
        'effective_status': 'pending',
        'expires_at': '2026-09-01T12:00:00Z',
        'last_sent_at': null,
        'send_count': 0,
        'created_at': '2026-08-30T11:00:00Z',
        'accepted_at': null,
        'revoked_at': null,
      }),
      throwsFormatException,
    );
  });

  test('CompanyInvitationPreviewModel maps sanitized preview row', () {
    final model = CompanyInvitationPreviewModel.fromRpcMap({
      'invitation_id': 'invitation-1',
      'company_id': 'company-1',
      'company_name': 'Horus Transport',
      'email_normalized': 'user@example.com',
      'invitation_role': 'operations',
      'effective_status': 'pending',
      'expires_at': '2026-09-01T12:00:00Z',
    });

    final entity = model.toEntity();
    expect(entity.companyName, 'Horus Transport');
    expect(entity.role, CompanyRole.operations);
    expect(entity.status, CompanyInvitationStatus.pending);
  });

  test(
    'CompanyInvitationTokenCodec hashes raw token as PostgreSQL bytea hex',
    () {
      const codec = CompanyInvitationTokenCodec();

      expect(
        codec.hashForPostgres('token-value'),
        r'\xe6c02a5742ea9d4de588eb9b9de7bed43dc17011552186bed3e98b2c5958ff4a',
      );
    },
  );

  group('CompanyCommandFailureMapper', () {
    const mapper = CompanyCommandFailureMapper();

    test('maps invitation permission error without backend details', () {
      final failure = mapper.fromCode(
        CompanyFailureCodes.invitationPermissionDenied,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, CompanyFailureCodes.invitationPermissionDenied);
      expect(failure.message, isNull);
    });

    test('maps delivery confirmation uncertainty distinctly', () {
      final failure = mapper.fromCode(
        'company_invitation_delivery_confirmation_invalid',
      );

      expect(failure, isA<ServerFailure>());
      expect(
        failure.code,
        CompanyFailureCodes.invitationDeliveryConfirmationUnknown,
      );
      expect(failure.message, isNull);
    });

    test('maps unknown backend code to sanitized server failure', () {
      final failure = mapper.fromCode('raw_backend_detail_should_not_escape');

      expect(failure, isA<ServerFailure>());
      expect(failure.message, isNull);
      expect(failure.code, isNot('raw_backend_detail_should_not_escape'));
    });
  });
}
