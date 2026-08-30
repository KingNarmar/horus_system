import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_preview.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_status.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/repositories/company_invitations_repository.dart';
import 'package:horus_system/features/company/domain/repositories/pending_company_invitation_repository.dart';
import 'package:horus_system/features/company/domain/usecases/accept_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/clear_pending_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_invitation_preview_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/get_pending_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/store_pending_company_invitation_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_invitation_acceptance_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_invitation_acceptance_state.dart';

void main() {
  test('captures token securely and waits for authentication', () async {
    final pendingRepository = _FakePendingInvitationRepository();
    final invitationsRepository = _FakeInvitationsRepository();
    final cubit = _buildCubit(pendingRepository, invitationsRepository);
    addTearDown(cubit.close);

    await cubit.captureToken(
      token: '  raw-token  ',
      isAuthenticated: false,
    );

    expect(pendingRepository.token, 'raw-token');
    expect(cubit.state, isA<CompanyInvitationAwaitingAuthentication>());
    expect(invitationsRepository.previewCalls, 0);
  });

  test('authenticated restore loads preview from pending token', () async {
    final pendingRepository = _FakePendingInvitationRepository()
      ..token = 'pending-token';
    final invitationsRepository = _FakeInvitationsRepository();
    final cubit = _buildCubit(pendingRepository, invitationsRepository);
    addTearDown(cubit.close);

    await cubit.restore(isAuthenticated: true);

    expect(invitationsRepository.lastToken, 'pending-token');
    expect(invitationsRepository.previewCalls, 1);
    final state = cubit.state;
    expect(state, isA<CompanyInvitationPreviewReady>());
    expect(
      (state as CompanyInvitationPreviewReady).preview.companyId,
      'company-1',
    );
  });

  test('accept is explicit and clears pending token after DB success', () async {
    final pendingRepository = _FakePendingInvitationRepository()
      ..token = 'pending-token';
    final invitationsRepository = _FakeInvitationsRepository();
    final cubit = _buildCubit(pendingRepository, invitationsRepository);
    addTearDown(cubit.close);

    await cubit.restore(isAuthenticated: true);
    expect(invitationsRepository.acceptCalls, 0);

    await cubit.accept();

    expect(invitationsRepository.acceptCalls, 1);
    expect(pendingRepository.clearCalls, 1);
    expect(pendingRepository.token, isNull);
    final state = cubit.state;
    expect(state, isA<CompanyInvitationAccepted>());
    final accepted = state as CompanyInvitationAccepted;
    expect(accepted.companyId, 'company-1');
    expect(accepted.pendingTokenCleanupFailure, isNull);
  });

  test('accepted DB result carries non-blocking secure cleanup failure', () async {
    final pendingRepository = _FakePendingInvitationRepository()
      ..token = 'pending-token'
      ..failClear = true;
    final invitationsRepository = _FakeInvitationsRepository();
    final cubit = _buildCubit(pendingRepository, invitationsRepository);
    addTearDown(cubit.close);

    await cubit.restore(isAuthenticated: true);
    await cubit.accept();

    expect(invitationsRepository.acceptCalls, 1);
    final state = cubit.state;
    expect(state, isA<CompanyInvitationAccepted>());
    final accepted = state as CompanyInvitationAccepted;
    expect(accepted.companyId, 'company-1');
    expect(accepted.pendingTokenCleanupFailure, isA<UnexpectedFailure>());
  });
}

CompanyInvitationAcceptanceCubit _buildCubit(
  PendingCompanyInvitationRepository pendingRepository,
  CompanyInvitationsRepository invitationsRepository,
) {
  return CompanyInvitationAcceptanceCubit(
    storePendingUseCase: StorePendingCompanyInvitationUseCase(
      pendingRepository,
    ),
    getPendingUseCase: GetPendingCompanyInvitationUseCase(pendingRepository),
    clearPendingUseCase: ClearPendingCompanyInvitationUseCase(
      pendingRepository,
    ),
    getPreviewUseCase: GetCompanyInvitationPreviewUseCase(
      invitationsRepository,
    ),
    acceptUseCase: AcceptCompanyInvitationUseCase(invitationsRepository),
  );
}

class _FakePendingInvitationRepository
    implements PendingCompanyInvitationRepository {
  String? token;
  int clearCalls = 0;
  bool failClear = false;

  @override
  Future<Result<void>> clearToken() async {
    clearCalls += 1;
    if (failClear) {
      return const FailureResult(UnexpectedFailure());
    }
    token = null;
    return const Success(null);
  }

  @override
  Future<Result<String?>> getToken() async => Success(token);

  @override
  Future<Result<void>> storeToken(String token) async {
    this.token = token;
    return const Success(null);
  }
}

class _FakeInvitationsRepository implements CompanyInvitationsRepository {
  int previewCalls = 0;
  int acceptCalls = 0;
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
  Future<Result<CompanyInvitationPreview>> getInvitationPreview(
    String token,
  ) async {
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
  }) async => const Success(null);

  @override
  Future<Result<void>> revokeInvitation({
    required String companyId,
    required String invitationId,
  }) async => const Success(null);

  @override
  Future<Result<void>> sendInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
  }) async => const Success(null);
}
