import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/usecases/get_switchable_company_contexts_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/company_switcher_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/company_switcher_state.dart';

void main() {
  test('loads active memberships with their company-specific roles', () async {
    final repository = _FakeCompanyContextRepository()
      ..onLoad = () async => Success([
        _context('company-a', CompanyRole.owner),
        _context('company-b', CompanyRole.viewer),
      ]);
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load();

    final state = cubit.state as CompanySwitcherLoaded;
    expect(state.companies.map((item) => item.companyId), [
      'company-a',
      'company-b',
    ]);
    expect(state.companies.last.role, CompanyRole.viewer);
  });

  test('preserves typed failure for a failed authoritative load', () async {
    final repository = _FakeCompanyContextRepository()
      ..onLoad = () async => const FailureResult(
        ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
      );
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load();

    expect(
      (cubit.state as CompanySwitcherFailure).failure.code,
      CompanyFailureCodes.companyNotAvailable,
    );
  });

  test('does not replace newer membership list with late response', () async {
    final first = Completer<Result<List<CurrentCompanyContext>>>();
    final second = Completer<Result<List<CurrentCompanyContext>>>();
    var reads = 0;
    final repository = _FakeCompanyContextRepository()
      ..onLoad = () => (++reads == 1 ? first.future : second.future);
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    final older = cubit.load();
    final newer = cubit.load();
    second.complete(Success([_context('company-b', CompanyRole.accountant)]));
    await newer;
    first.complete(Success([_context('company-a', CompanyRole.owner)]));
    await older;

    final state = cubit.state as CompanySwitcherLoaded;
    expect(state.companies.single.companyId, 'company-b');
  });

  test('closing picker cancels stale state emissions', () async {
    final pending = Completer<Result<List<CurrentCompanyContext>>>();
    final repository = _FakeCompanyContextRepository()
      ..onLoad = () => pending.future;
    final cubit = _cubit(repository);

    final loading = cubit.load();
    await cubit.close();
    pending.complete(Success([_context('company-a', CompanyRole.owner)]));
    await loading;

    expect(cubit.isClosed, isTrue);
  });
}

CompanySwitcherCubit _cubit(CompanyContextRepository repository) =>
    CompanySwitcherCubit(
      getCompanies: GetSwitchableCompanyContextsUseCase(repository),
    );

CurrentCompanyContext _context(String id, CompanyRole role) =>
    CurrentCompanyContext(
      company: Company(id: id, name: 'Company $id'),
      role: role,
    );

final class _FakeCompanyContextRepository implements CompanyContextRepository {
  Future<Result<List<CurrentCompanyContext>>> Function()? onLoad;

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() =>
      onLoad?.call() ?? Future.value(const Success(<CurrentCompanyContext>[]));

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async =>
      const FailureResult(
        ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
      );

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success(null);

  @override
  Future<Result<void>> clearCurrentCompanyContext() async =>
      const Success(null);
}
