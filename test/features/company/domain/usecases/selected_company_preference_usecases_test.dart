import 'package:test/test.dart';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/repositories/company_context_repository.dart';
import 'package:horus_system/features/company/domain/repositories/selected_company_preference_repository.dart';
import 'package:horus_system/features/company/domain/usecases/load_current_company_context_usecase.dart';
import 'package:horus_system/features/company/domain/usecases/remember_selected_company_usecase.dart';

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
    'restores last user company only when server says it is active',
    () async {
      final source = _Contexts([_a, _b]);
      final preference = _Preferences()..values['user-a'] = 'company-b';

      final result = await LoadCurrentCompanyContextUseCase(
        source,
        preferences: preference,
      )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

      expect(result.dataOrNull, same(_b));
      expect(source.selected, 'company-b');
      expect(source.loads, 1);
      expect(preference.readUsers, ['user-a']);
      expect(preference.saved, isEmpty);
    },
  );

  test('revoked preference falls back to fresh eligible company', () async {
    final source = _Contexts([_a]);
    final preference = _Preferences()..values['user-a'] = 'company-b';

    final result = await LoadCurrentCompanyContextUseCase(
      source,
      preferences: preference,
    )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

    expect(result.dataOrNull, same(_a));
    expect(source.selected, 'company-a');
    expect(preference.saved, isEmpty);
  });

  test('corrupt or missing preference is never an access grant', () async {
    for (final value in [null, '', 'foreign-company', ' company-b\u0000']) {
      final source = _Contexts([_a, _b]);
      final preference = _Preferences();
      if (value != null) preference.values['user-a'] = value;

      final result = await LoadCurrentCompanyContextUseCase(
        source,
        preferences: preference,
      )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

      expect(result.dataOrNull, same(_a));
      expect(source.selected, 'company-a');
    }
  });

  test('never reads preference if active membership list is empty', () async {
    final source = _Contexts([]);
    final preference = _Preferences()..values['user-a'] = 'company-b';

    final result = await LoadCurrentCompanyContextUseCase(
      source,
      preferences: preference,
    )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

    expect(result.dataOrNull, isNull);
    expect(source.clears, 1);
    expect(preference.readUsers, isEmpty);
  });

  test('server read failure never grants cached preferred company', () async {
    final source = _Contexts([_a, _b])
      ..loadFailure = const FailureResult(
        NetworkFailure(code: CompanyFailureCodes.contextConnectionUnavailable),
      );
    final preference = _Preferences()..values['user-a'] = 'company-b';

    final result = await LoadCurrentCompanyContextUseCase(
      source,
      preferences: preference,
    )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

    expect(
      result.failureOrNull?.code,
      CompanyFailureCodes.contextConnectionUnavailable,
    );
    expect(source.selected, isNull);
    expect(preference.readUsers, isEmpty);
  });

  test(
    'optional storage failure falls back to a server-verified company',
    () async {
      final source = _Contexts([_a, _b]);
      final preference = _Preferences()..readFailure = true;

      final result = await LoadCurrentCompanyContextUseCase(
        source,
        preferences: preference,
      )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull, same(_a));
      expect(source.selected, 'company-a');
    },
  );

  test('identity mismatch still denies all company selection', () async {
    final source = _Contexts([_a, _b]);
    final preference = _Preferences()..readAuthFailure = true;
    final result = await LoadCurrentCompanyContextUseCase(
      source,
      preferences: preference,
    )(const LoadCurrentCompanyContextParams(userId: 'user-a'));

    expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
    expect(source.selected, isNull);
  });

  test('remember validates actor and saves a verified company ID', () async {
    final preference = _Preferences();
    final useCase = RememberSelectedCompanyUseCase(preference);

    expect(
      (await useCase(
        const RememberSelectedCompanyParams(userId: '', companyId: 'company-a'),
      )).failureOrNull?.code,
      CompanyFailureCodes.authRequired,
    );
    expect(
      (await useCase(
        const RememberSelectedCompanyParams(userId: 'user-a', companyId: ' '),
      )).failureOrNull?.code,
      CompanyFailureCodes.companyNotAvailable,
    );
    final result = await useCase(
      const RememberSelectedCompanyParams(
        userId: 'user-a',
        companyId: ' company-b ',
      ),
    );
    expect(result.failureOrNull, isNull);
    expect(preference.values['user-a'], 'company-b');
    expect(preference.saved, ['user-a:company-b']);
  });

  test('preference storage write failure is a typed Result', () async {
    final preference = _Preferences()..writeFailure = true;
    final result = await RememberSelectedCompanyUseCase(preference)(
      const RememberSelectedCompanyParams(
        userId: 'user-a',
        companyId: 'company-b',
      ),
    );
    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}

final class _Contexts implements CompanyContextRepository {
  List<CurrentCompanyContext> contexts;
  Result<List<CurrentCompanyContext>>? loadFailure;
  int loads = 0;
  int clears = 0;
  String? selected;

  _Contexts(this.contexts);

  @override
  Future<Result<List<CurrentCompanyContext>>> loadUserCompanyContexts() async {
    loads++;
    return loadFailure ?? Success(contexts);
  }

  @override
  Future<Result<CurrentCompanyContext>> selectCompany(String companyId) async {
    selected = companyId;
    for (final context in contexts) {
      if (context.companyId == companyId) return Success(context);
    }
    return const FailureResult(
      ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
    );
  }

  @override
  Future<Result<void>> clearCurrentCompanyContext() async {
    clears++;
    return const Success<void>(null);
  }

  @override
  Future<Result<CurrentCompanyContext?>> getCurrentCompanyContext() async =>
      const Success(null);
}

final class _Preferences implements SelectedCompanyPreferenceRepository {
  final Map<String, String> values = {};
  final List<String> readUsers = [];
  final List<String> saved = [];
  bool readFailure = false;
  bool readAuthFailure = false;
  bool writeFailure = false;

  @override
  Future<Result<String?>> read(String userId) async {
    readUsers.add(userId);
    if (readAuthFailure) {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    }
    if (readFailure) return const FailureResult(UnexpectedFailure());
    return Success(values[userId]);
  }

  @override
  Future<Result<void>> save({
    required String userId,
    required String companyId,
  }) async {
    if (writeFailure) return const FailureResult(UnexpectedFailure());
    values[userId] = companyId;
    saved.add('$userId:$companyId');
    return const Success<void>(null);
  }
}
