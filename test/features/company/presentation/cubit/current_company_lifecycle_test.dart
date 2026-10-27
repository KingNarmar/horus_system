import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_membership_change.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/repositories/company_membership_changes_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/watch_company_membership_changes_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_state.dart';
import 'package:test/test.dart';

void main() {
  test('revalidation applies authoritative role downgrade', () async {
    final repository = _FakeCompanyContextRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    await cubit.loadCurrentCompanyContext();
    expect(
      (cubit.state as CurrentCompanyLoaded).context.role,
      CompanyRole.owner,
    );

    repository.contexts = [_context(CompanyRole.viewer)];
    await cubit.revalidateSelectedCompany();

    final latest = cubit.state as CurrentCompanyLoaded;
    expect(latest.context.role, CompanyRole.viewer);
    expect(latest.context.companyId, 'company-a');
    expect(repository.loads, 2);
  });

  test(
    'revoked membership clears selected company and hides its shell',
    () async {
      final repository = _FakeCompanyContextRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadCurrentCompanyContext();
      repository.contexts = const [];
      await cubit.revalidateSelectedCompany();

      expect(cubit.state, isA<CurrentCompanyEmpty>());
      expect(repository.clears, 1);
    },
  );

  test(
    'reactivated membership restores the company from empty state',
    () async {
      final repository = _FakeCompanyContextRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      repository.contexts = const [];
      await cubit.loadCurrentCompanyContext();
      expect(cubit.state, isA<CurrentCompanyEmpty>());

      repository.contexts = [_context(CompanyRole.operations)];
      await cubit.revalidateSelectedCompany();

      final recovered = cubit.state as CurrentCompanyLoaded;
      expect(recovered.context.role, CompanyRole.operations);
      expect(repository.loads, 2);
    },
  );

  test('rechecking empty context cannot restore a revoked member', () async {
    final repository = _FakeCompanyContextRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    repository.contexts = const [];
    await cubit.loadCurrentCompanyContext();
    await cubit.revalidateSelectedCompany();

    expect(cubit.state, isA<CurrentCompanyEmpty>());
    expect(repository.loads, 2);
  });

  test('membership signal refreshes an already-open company role', () async {
    final repository = _FakeCompanyContextRepository();
    final changes = _FakeMembershipChangesRepository();
    final cubit = _createCubit(repository, changes)
      ..startWatchingMembership('user-a');
    addTearDown(() async {
      await cubit.close();
      await changes.dispose();
    });

    await cubit.loadCurrentCompanyContext();
    repository.contexts = [_context(CompanyRole.operations)];
    changes.notify();
    await Future<void>.delayed(Duration.zero);

    expect(
      (cubit.state as CurrentCompanyLoaded).context.role,
      CompanyRole.operations,
    );
  });

  test(
    'membership signal recovers reactivated company without login',
    () async {
      final repository = _FakeCompanyContextRepository();
      final changes = _FakeMembershipChangesRepository();
      final cubit = _createCubit(repository, changes)
        ..startWatchingMembership('user-a');
      addTearDown(() async {
        await cubit.close();
        await changes.dispose();
      });

      repository.contexts = const [];
      await cubit.loadCurrentCompanyContext();
      expect(cubit.state, isA<CurrentCompanyEmpty>());

      repository.contexts = [_context(CompanyRole.operations)];
      changes.notify();
      await Future<void>.delayed(Duration.zero);

      expect(
        (cubit.state as CurrentCompanyLoaded).context.role,
        CompanyRole.operations,
      );
    },
  );

  test(
    'revalidation retains mounted company context until server responds',
    () async {
      final repository = _FakeCompanyContextRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadCurrentCompanyContext();
      final pending = Completer<Result<List<CurrentCompanyContext>>>();
      repository.pendingLoad = pending;

      final validation = cubit.revalidateSelectedCompany();
      final verifying = cubit.state as CurrentCompanyVerifying;
      expect(verifying.context.companyId, 'company-a');
      expect(verifying.context.role, CompanyRole.owner);

      repository.contexts = [_context(CompanyRole.owner)];
      pending.complete(Success(repository.contexts));
      await validation;
      expect(cubit.state, isA<CurrentCompanyLoaded>());
    },
  );

  test(
    'late company verification cannot resurrect context after sign-out',
    () async {
      final repository = _FakeCompanyContextRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadCurrentCompanyContext();
      final pending = Completer<Result<List<CurrentCompanyContext>>>();
      repository.pendingLoad = pending;
      final validation = cubit.revalidateSelectedCompany();
      await cubit.clearCurrentCompanyContext();
      pending.complete(Success([_context(CompanyRole.owner)]));
      await validation;

      expect(cubit.state, isA<CurrentCompanyEmpty>());
    },
  );
}

CurrentCompanyCubit _createCubit(
  _FakeCompanyContextRepository repository, [
  _FakeMembershipChangesRepository? changes,
]) => CurrentCompanyCubit(
  loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
    repository,
  ),
  selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(repository),
  refreshSelectedCompanyContextUseCase: RefreshSelectedCompanyContextUseCase(
    repository,
  ),
  clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
    repository,
  ),
  watchMembershipChangesUseCase: changes == null
      ? null
      : WatchCompanyMembershipChangesUseCase(changes),
);

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(id: 'company-a', name: 'Test Company'),
  role: role,
);

final class _FakeMembershipChangesRepository
    implements CompanyMembershipChangesRepository {
  final _controller =
      StreamController<Result<CompanyMembershipChange>>.broadcast();

  @override
  Stream<Result<CompanyMembershipChange>> watchChanges({
    required String userId,
  }) => _controller.stream;

  void notify() =>
      _controller.add(const Success(CompanyMembershipChange.invalidated));

  Future<void> dispose() => _controller.close();
}

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  List<CurrentCompanyContext> contexts = [_context(CompanyRole.owner)];
  Completer<Result<List<CurrentCompanyContext>>>? pendingLoad;
  int loads = 0;
  int clears = 0;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads++;
    return pendingLoad?.future ?? Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    for (final context in contexts) {
      if (context.companyId == companyId) return Success(context);
    }
    return const FailureResult(
      ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
    );
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      Success(contexts.isEmpty ? null : contexts.first);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    clears++;
    return const Success(null);
  }
}
