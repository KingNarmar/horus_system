import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_preview.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_invitations_repository.dart';
import 'package:horus_system/features/company/domain/usecases/accept_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_invitation_preview_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/resend_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/revoke_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/send_company_invitation_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

void main() {
  group('SendCompanyInvitationUseCase', () {
    test('normalizes email before delegating for an allowed role', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final useCase = SendCompanyInvitationUseCase(repository);

      final result = await useCase(
        SendCompanyInvitationParams(
          currentCompanyContext: _context(CompanyRole.owner),
          email: '  USER@Example.COM  ',
          role: CompanyRole.admin,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastEmail, 'user@example.com');
      expect(repository.lastRole, CompanyRole.admin);
      expect(repository.sendCalls, 1);
    });

    test('rejects invalid email before repository call', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final useCase = SendCompanyInvitationUseCase(repository);

      final result = await useCase(
        SendCompanyInvitationParams(
          currentCompanyContext: _context(CompanyRole.owner),
          email: 'invalid',
          role: CompanyRole.viewer,
        ),
      );

      expect(result.failureOrNull?.code, CompanyFailureCodes.invitationEmailInvalid);
      expect(repository.sendCalls, 0);
    });

    test('admin cannot invite admin', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final useCase = SendCompanyInvitationUseCase(repository);

      final result = await useCase(
        SendCompanyInvitationParams(
          currentCompanyContext: _context(CompanyRole.admin),
          email: 'admin@example.com',
          role: CompanyRole.admin,
        ),
      );

      expect(result.failureOrNull?.code, CompanyFailureCodes.invitationRoleNotAllowed);
      expect(repository.sendCalls, 0);
    });
  });

  group('invitation id command validation', () {
    test('resend requires invitation id', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final result = await ResendCompanyInvitationUseCase(repository)(
        ResendCompanyInvitationParams(
          currentCompanyContext: _context(CompanyRole.owner),
          invitationId: '   ',
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationInvitationIdRequired,
      );
      expect(repository.resendCalls, 0);
    });

    test('revoke requires invitation id', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final result = await RevokeCompanyInvitationUseCase(repository)(
        RevokeCompanyInvitationParams(
          currentCompanyContext: _context(CompanyRole.admin),
          invitationId: '',
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationInvitationIdRequired,
      );
      expect(repository.revokeCalls, 0);
    });
  });

  group('invitation token command validation', () {
    test('preview requires token', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final result = await GetCompanyInvitationPreviewUseCase(repository)('  ');

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationInvitationTokenRequired,
      );
      expect(repository.previewCalls, 0);
    });

    test('accept requires token', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final result = await AcceptCompanyInvitationUseCase(repository)('');

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationInvitationTokenRequired,
      );
      expect(repository.acceptCalls, 0);
    });

    test('preview trims token before repository call', () async {
      final repository = _FakeCompanyInvitationsRepository();
      final result = await GetCompanyInvitationPreviewUseCase(repository)(
        '  token-value  ',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.lastToken, 'token-value');
      expect(repository.previewCalls, 1);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}

class _FakeCompanyInvitationsRepository implements CompanyInvitationsRepository {
  int sendCalls = 0;
  int resendCalls = 0;
  int revokeCalls = 0;
  int previewCalls = 0;
  int acceptCalls = 0;
  String? lastCompanyId;
  String? lastEmail;
  CompanyRole? lastRole;
  String? lastToken;

  @override
  Future<Result<String>> acceptInvitation(String token) async {
    acceptCalls += 1;
    lastToken = token;
    return const Success('company-1');
  }

  @override
  Future<Result<List<CompanyInvitation>>> getInvitations(String companyId) async {
    return const Success(<CompanyInvitation>[]);
  }

  @override
  Future<Result<CompanyInvitationPreview>> getInvitationPreview(String token) async {
    previewCalls += 1;
    lastToken = token;
    return Success(
      CompanyInvitationPreview(
        invitationId: 'invitation-1',
        companyId: 'company-1',
        companyName: 'Company',
        email: 'user@example.com',
        role: CompanyRole.viewer,
        status: CompanyInvitationStatus.pending,
        expiresAt: DateTime.utc(2026, 9, 1),
      ),
    );
  }

  @override
  Future<Result<void>> resendInvitation({
    required String companyId,
    required String invitationId,
  }) async {
    resendCalls += 1;
    return const Success(null);
  }

  @override
  Future<Result<void>> revokeInvitation({
    required String companyId,
    required String invitationId,
  }) async {
    revokeCalls += 1;
    return const Success(null);
  }

  @override
  Future<Result<void>> sendInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
  }) async {
    sendCalls += 1;
    lastCompanyId = companyId;
    lastEmail = email;
    lastRole = role;
    return const Success(null);
  }
}
