import 'dart:async';

import 'package:test/test.dart';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/repositories/selected_company_preference_repository.dart';
import 'package:horus_system/features/company/domain/usecases/clear_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/refresh_selected_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/remember_selected_company_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/select_current_company_usecase.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_cubit.dart';
import 'package:horus_system/features/company/presentation/cubit/current_company_state.dart';

const _a = CurrentCompanyContext(
  company: Company(id: 'company-a', name: 'A'),
  role: CompanyRole.owner,
);
const _b = CurrentCompanyContext(
  company: Company(id: 'company-b', name: 'B'),
  role: CompanyRole.viewer,
);

void main() {
  test(
    'successful server-verified switch survives a simulated cold start',
    () async {
      final server = _Server([_a, _b]);
      final preference = _Preference();
      final first = _createCubit(server, preference);
      first.startWatchingMembership('user-a');
      await first.loadCurrentCompanyContext();
      expect(
        (first.state as CurrentCompanyLoaded).context.companyId,
        'company-a',
      );
      expect(
        (await first.switchActiveCompany('company-b')).failureOrNull,
        isNull,
      );
      expect(preference.values['user-a'], 'company-b');
      await first.close();

      final restarted = _createCubit(_Server([_a, _b]), preference);
      addTearDown(restarted.close);
      restarted.startWatchingMembership('user-a');
      await restarted.loadCurrentCompanyContext();
      expect((restarted.state as CurrentCompanyLoaded).context, _b);
    },
  );

  test('sign-out and account switch cannot borrow another selection', () async {
    final server = _Server([_a, _b]);
    final preference = _Preference();
    final cubit = _createCubit(server, preference);
    addTearDown(cubit.close);

    cubit.startWatchingMembership('user-a');
    await cubit.loadCurrentCompanyContext();
    await cubit.switchActiveCompany('company-b');
    await cubit.stopWatchingMembership();
    await cubit.clearCurrentCompanyContext();

    cubit.startWatchingMembership('user-b');
    await cubit.loadCurrentCompanyContext();
    expect(
      (cubit.state as CurrentCompanyLoaded).context.companyId,
      'company-a',
    );
    expect(preference.values['user-b'], isNull);

    await cubit.stopWatchingMembership();
    await cubit.clearCurrentCompanyContext();
    cubit.startWatchingMembership('user-a');
    await cubit.loadCurrentCompanyContext();
    expect(
      (cubit.state as CurrentCompanyLoaded).context.companyId,
      'company-b',
    );
  });

  test(
    'revocation falls back to remaining active company; no stale access',
    () async {
      final preference = _Preference()..values['user-a'] = 'company-b';
      final server = _Server([_a]);
      final cubit = _createCubit(server, preference);
      addTearDown(cubit.close);

      cubit.startWatchingMembership('user-a');
      await cubit.loadCurrentCompanyContext();
      expect((cubit.state as CurrentCompanyLoaded).context, _a);
      expect(server.selected, 'company-a');
      expect(server.selections, isNot(contains('company-b')));

      server.contexts = [];
      await cubit.revalidateSelectedCompany();
      expect(cubit.state, isA<CurrentCompanyEmpty>());

      server.contexts = [_b];
      await cubit.revalidateSelectedCompany();
      expect((cubit.state as CurrentCompanyLoaded).context, _b);
    },
  );

  test('offline startup does not display cached company data', () async {
    final server = _Server([_a, _b])
      ..failure = const FailureResult(
        NetworkFailure(code: CompanyFailureCodes.contextConnectionUnavailable),
      );
    final preference = _Preference()..values['user-a'] = 'company-b';
    final cubit = _createCubit(server, preference);
    addTearDown(cubit.close);

    cubit.startWatchingMembership('user-a');
    await cubit.loadCurrentCompanyContext();
    expect(cubit.state, isA<CurrentCompanyFailure>());
    expect(server.selected, isNull);

    server.failure = null;
    await cubit.revalidateSelectedCompany();
    expect((cubit.state as CurrentCompanyLoaded).context, _b);
  });

  test('denied switch cannot persist a forbidden company', () async {
    final server = _Server([_a]);
    final preference = _Preference();
    final cubit = _createCubit(server, preference);
    addTearDown(cubit.close);

    cubit.startWatchingMembership('user-a');
    await cubit.loadCurrentCompanyContext();
    final result = await cubit.switchActiveCompany('company-b');
    expect(result.failureOrNull?.code, CompanyFailureCodes.companyNotAvailable);
    expect(preference.values, isEmpty);
    expect((cubit.state as CurrentCompanyLoaded).context, _a);
  });

  test('late startup result cannot restore old user shell', () async {
    final server = _Server([_a, _b]);
    final preference = _Preference();
    final pending = Completer<Result<String?>>();
    preference.nextRead = pending;
    final cubit = _createCubit(server, preference);
    addTearDown(cubit.close);

    cubit.startWatchingMembership('user-a');
    final older = cubit.loadCurrentCompanyContext();
    await Future<void>.delayed(Duration.zero);
    await cubit.stopWatchingMembership();
    await cubit.clearCurrentCompanyContext();
    cubit.startWatchingMembership('user-b');
    await cubit.loadCurrentCompanyContext();

    pending.complete(const Success('company-b'));
    await older;
    expect((cubit.state as CurrentCompanyLoaded).context, _a);
  });

  test(
    'late preference write cannot show the former shell after identity change',
    () async {
      final server = _Server([_a, _b]);
      final preference = _Preference();
      final pendingWrite = Completer<Result<void>>();
      preference.nextSave = pendingWrite;
      final cubit = _createCubit(server, preference);
      addTearDown(cubit.close);

      cubit.startWatchingMembership('user-a');
      await cubit.loadCurrentCompanyContext();
      final switchToB = cubit.switchActiveCompany('company-b');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<CurrentCompanyLoading>());

      await cubit.stopWatchingMembership();
      await cubit.clearCurrentCompanyContext();
      cubit.startWatchingMembership('user-b');
      await cubit.loadCurrentCompanyContext();
      expect((cubit.state as CurrentCompanyLoaded).context, _a);

      pendingWrite.complete(const Success<void>(null));
      await switchToB;
      expect((cubit.state as CurrentCompanyLoaded).context, _a);
      expect(preference.values['user-b'], isNull);
    },
  );

  test(
    'local preference write failure does not revoke verified switch',
    () async {
      final server = _Server([_a, _b]);
      final preference = _Preference()..writeFailure = true;
      final cubit = _createCubit(server, preference);
      addTearDown(cubit.close);

      cubit.startWatchingMembership('user-a');
      await cubit.loadCurrentCompanyContext();
      final result = await cubit.switchActiveCompany('company-b');
      expect(result.failureOrNull, isNull);
      expect((cubit.state as CurrentCompanyLoaded).context, _b);
    },
  );
}

CurrentCompanyCubit _createCubit(_Server repository, _Preference preferences) =>
    CurrentCompanyCubit(
      loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
        repository,
        preferences: preferences,
      ),
      rememberSelectedCompanyUseCase: RememberSelectedCompanyUseCase(
        preferences,
      ),
      selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(repository),
      refreshSelectedCompanyContextUseCase:
          RefreshSelectedCompanyContextUseCase(repository),
      clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
        repository,
      ),
    );

final class _Server implements CompanyContextRepository {
  List<CurrentCompanyContext> contexts;
  Result<List<CurrentCompanyContext>>? failure;
  final List<String> selections = [];
  String? selected;
  int loads = 0;

  _Server(this.contexts);

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads++;
    return failure ?? Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    selections.add(companyId);
    for (final context in contexts) {
      if (context.companyId == companyId) {
        selected = companyId;
        return Success(context);
      }
    }
    return const FailureResult(
      ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
    );
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    selected = null;
    return const Success<void>(null);
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success(null);
}

final class _Preference implements SelectedCompanyPreferenceRepository {
  final Map<String, String> values = {};
  Completer<Result<String?>>? nextRead;
  Completer<Result<void>>? nextSave;
  bool writeFailure = false;

  @override
  Future<Result<String?>> read(String userId) async {
    final pending = nextRead;
    nextRead = null;
    if (pending != null) return pending.future;
    return Success(values[userId]);
  }

  @override
  Future<Result<void>> save({
    required String userId,
    required String companyId,
  }) async {
    if (writeFailure) return const FailureResult(UnexpectedFailure());
    final pending = nextSave;
    nextSave = null;
    if (pending != null) {
      final result = await pending.future;
      if (result.failureOrNull != null) return result;
    }
    values[userId] = companyId;
    return const Success<void>(null);
  }
}
