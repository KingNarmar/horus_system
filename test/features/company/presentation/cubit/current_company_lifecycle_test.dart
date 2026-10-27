import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
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

CurrentCompanyCubit _createCubit(_FakeCompanyContextRepository repository) =>
    CurrentCompanyCubit(
      loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
        repository,
      ),
      selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(repository),
      refreshSelectedCompanyContextUseCase:
          RefreshSelectedCompanyContextUseCase(repository),
      clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
        repository,
      ),
    );

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(id: 'company-a', name: 'Test Company'),
  role: role,
);

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
