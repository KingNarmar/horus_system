import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_preview.dart';
import 'package:horus_system/features/company/domain/entities/company_invitation_status.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_invitations_repository.dart';
import 'package:horus_system/features/company/domain/usecases/get_company_invitations_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/resend_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/revoke_company_invitation_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/send_company_invitation_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_invitations_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_invitations_state.dart';

void main() {
  test(
    'late result from old company cannot replace newly selected scope',
    () async {
      final repository = _FakeInvitationsRepository.withDeferredLoads();
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);

      final loadA = cubit.load(_context('company-a'));
      await Future<void>.delayed(Duration.zero);
      final loadB = cubit.load(_context('company-b'));

      repository.completeLoad(
        'company-b',
        Success([_invitation('invitation-b', 'company-b')]),
      );
      await loadB;

      var state = cubit.state;
      expect(state, isA<CompanyInvitationsLoaded>());
      expect(state.companyId, 'company-b');
      expect(
        (state as CompanyInvitationsLoaded).invitations.single.id,
        'invitation-b',
      );

      repository.completeLoad(
        'company-a',
        Success([_invitation('invitation-a', 'company-a')]),
      );
      await loadA;

      state = cubit.state;
      expect(state, isA<CompanyInvitationsLoaded>());
      expect(state.companyId, 'company-b');
      expect(
        (state as CompanyInvitationsLoaded).invitations.single.id,
        'invitation-b',
      );
    },
  );

  test('initial list failure is represented as load failure', () async {
    final repository = _FakeInvitationsRepository(
      loadResults: {'company-a': const FailureResult(UnexpectedFailure())},
    );
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context('company-a'));

    expect(cubit.state, isA<CompanyInvitationsLoadFailure>());
  });

  test('command failure preserves previously loaded invitations', () async {
    final invitation = _invitation('invitation-1', 'company-a');
    final repository = _FakeInvitationsRepository(
      loadResults: {
        'company-a': Success([invitation]),
      },
      resendResult: const FailureResult(UnexpectedFailure()),
    );
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);
    final context = _context('company-a');

    await cubit.load(context);
    await cubit.resend(
      currentCompanyContext: context,
      invitationId: invitation.id,
    );

    final state = cubit.state;
    expect(state, isA<CompanyInvitationsCommandFailure>());
    expect((state as CompanyInvitationsCommandFailure).invitations, [
      invitation,
    ]);
  });

  test(
    'send failure after successful empty load stays a command failure',
    () async {
      final repository = _FakeInvitationsRepository(
        loadResults: {'company-a': const Success(<CompanyInvitation>[])},
        sendResult: const FailureResult(
          ServerFailure(
            code: CompanyFailureCodes.invitationDeliveryNotConfigured,
          ),
        ),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      final context = _context('company-a');

      await cubit.load(context);
      await cubit.send(
        currentCompanyContext: context,
        email: 'user@example.com',
        role: CompanyRole.viewer,
      );

      final state = cubit.state;
      expect(state, isA<CompanyInvitationsCommandFailure>());
      final failureState = state as CompanyInvitationsCommandFailure;
      expect(failureState.invitations, isEmpty);
      expect(
        failureState.failure.code,
        CompanyFailureCodes.invitationDeliveryNotConfigured,
      );
      expect(repository.loadCalls['company-a'], 1);
    },
  );

  test(
    'delivery failure emits command failure then refreshes authoritative list',
    () async {
      final refreshedInvitation = _invitation('invitation-1', 'company-a');
      final repository = _FakeInvitationsRepository(
        loadResults: {'company-a': const Success(<CompanyInvitation>[])},
        sendResult: const FailureResult(
          ServerFailure(code: CompanyFailureCodes.invitationDeliveryFailed),
        ),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      final context = _context('company-a');

      await cubit.load(context);
      repository.loadResults['company-a'] = Success([refreshedInvitation]);

      final stateSequence = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CompanyInvitationsCommandInProgress>(),
          isA<CompanyInvitationsCommandFailure>(),
          isA<CompanyInvitationsLoaded>(),
        ]),
      );

      await cubit.send(
        currentCompanyContext: context,
        email: 'user@example.com',
        role: CompanyRole.viewer,
      );
      await stateSequence;

      final state = cubit.state;
      expect(state, isA<CompanyInvitationsLoaded>());
      expect((state as CompanyInvitationsLoaded).invitations, [
        refreshedInvitation,
      ]);
      expect(repository.loadCalls['company-a'], 2);
    },
  );

  test(
    'failed refresh after delivery confirmation ambiguity preserves command failure',
    () async {
      final repository = _FakeInvitationsRepository(
        loadResults: {'company-a': const Success(<CompanyInvitation>[])},
        sendResult: const FailureResult(
          ServerFailure(
            code: CompanyFailureCodes.invitationDeliveryConfirmationUnknown,
          ),
        ),
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      final context = _context('company-a');

      await cubit.load(context);
      repository.loadResults['company-a'] = const FailureResult(
        UnexpectedFailure(),
      );

      await cubit.send(
        currentCompanyContext: context,
        email: 'user@example.com',
        role: CompanyRole.viewer,
      );

      final state = cubit.state;
      expect(state, isA<CompanyInvitationsCommandFailure>());
      expect(
        (state as CompanyInvitationsCommandFailure).failure.code,
        CompanyFailureCodes.invitationDeliveryConfirmationUnknown,
      );
      expect(repository.loadCalls['company-a'], 2);
    },
  );

  test('failed resend does not prevent a later revoke command', () async {
    final invitation = _invitation('invitation-1', 'company-a');
    final repository = _FakeInvitationsRepository(
      loadResults: {
        'company-a': Success([invitation]),
      },
      resendResult: const FailureResult(UnexpectedFailure()),
    );
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);
    final context = _context('company-a');

    await cubit.load(context);
    await cubit.resend(
      currentCompanyContext: context,
      invitationId: invitation.id,
    );
    expect(cubit.state, isA<CompanyInvitationsCommandFailure>());

    await cubit.revoke(
      currentCompanyContext: context,
      invitationId: invitation.id,
    );

    expect(repository.revokeCalls, 1);
    expect(cubit.state, isA<CompanyInvitationsLoaded>());
  });

  test(
    'successful send emits command success and reloads same scope',
    () async {
      final repository = _FakeInvitationsRepository(
        loadResults: {'company-a': const Success(<CompanyInvitation>[])},
      );
      final cubit = _buildCubit(repository);
      addTearDown(cubit.close);
      final context = _context('company-a');

      await cubit.load(context);
      repository.loadResults['company-a'] = Success([
        _invitation('invitation-1', 'company-a'),
      ]);

      final stateSequence = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CompanyInvitationsCommandInProgress>(),
          isA<CompanyInvitationsCommandSucceeded>(),
          isA<CompanyInvitationsLoaded>(),
        ]),
      );

      await cubit.send(
        currentCompanyContext: context,
        email: 'user@example.com',
        role: CompanyRole.viewer,
      );
      await stateSequence;

      final state = cubit.state;
      expect(state, isA<CompanyInvitationsLoaded>());
      expect((state as CompanyInvitationsLoaded).invitations.length, 1);
      expect(repository.sendCalls, 1);
      expect(repository.loadCalls['company-a'], 2);
    },
  );
}

CompanyInvitationsCubit _buildCubit(CompanyInvitationsRepository repository) {
  return CompanyInvitationsCubit(
    getInvitationsUseCase: GetCompanyInvitationsUseCase(repository),
    sendInvitationUseCase: SendCompanyInvitationUseCase(repository),
    resendInvitationUseCase: ResendCompanyInvitationUseCase(repository),
    revokeInvitationUseCase: RevokeCompanyInvitationUseCase(repository),
  );
}

CurrentCompanyContext _context(String companyId) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: companyId),
    role: CompanyRole.owner,
  );
}

CompanyInvitation _invitation(String id, String companyId) {
  return CompanyInvitation(
    id: id,
    companyId: companyId,
    email: '$id@example.com',
    role: CompanyRole.viewer,
    status: CompanyInvitationStatus.pending,
    expiresAt: DateTime.utc(2026, 9, 1),
    lastSentAt: null,
    sendCount: 0,
    createdAt: DateTime.utc(2026, 8, 30),
    acceptedAt: null,
    revokedAt: null,
  );
}

class _FakeInvitationsRepository implements CompanyInvitationsRepository {
  final Map<String, Result<List<CompanyInvitation>>> loadResults;
  final Map<String, Completer<Result<List<CompanyInvitation>>>> _deferredLoads;
  Result<void> sendResult;
  Result<void> resendResult;
  int sendCalls = 0;
  int revokeCalls = 0;
  final Map<String, int> loadCalls = {};

  _FakeInvitationsRepository({
    Map<String, Result<List<CompanyInvitation>>>? loadResults,
    this.sendResult = const Success(null),
    this.resendResult = const Success(null),
  }) : loadResults = loadResults ?? {},
       _deferredLoads = {};

  _FakeInvitationsRepository.withDeferredLoads()
    : loadResults = {},
      _deferredLoads = {},
      sendResult = const Success(null),
      resendResult = const Success(null);

  void completeLoad(String companyId, Result<List<CompanyInvitation>> result) {
    _deferredLoads[companyId]?.complete(result);
  }

  @override
  Future<Result<String>> acceptInvitation(String token) async {
    return const Success('company-a');
  }

  @override
  Future<Result<List<CompanyInvitation>>> getInvitations(String companyId) {
    loadCalls[companyId] = (loadCalls[companyId] ?? 0) + 1;
    if (loadResults.containsKey(companyId)) {
      return Future.value(loadResults[companyId]!);
    }
    return (_deferredLoads[companyId] ??=
            Completer<Result<List<CompanyInvitation>>>())
        .future;
  }

  @override
  Future<Result<CompanyInvitationPreview>> getInvitationPreview(
    String token,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> resendInvitation({
    required String companyId,
    required String invitationId,
  }) async => resendResult;

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
    return sendResult;
  }
}
