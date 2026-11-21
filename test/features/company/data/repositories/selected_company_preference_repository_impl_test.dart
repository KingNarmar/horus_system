import 'dart:async';

import 'package:test/test.dart';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/features/company/data/datasources/selected_company_preference_local_data_source.dart';
import 'package:horus_system/features/company/data/repositories/selected_company_preference_repository_impl.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';

void main() {
  test('per-user preference is isolated on one shared device', () async {
    var actor = 'user-a';
    final local = _Local();
    final repository = SelectedCompanyPreferenceRepositoryImpl(
      localDataSource: local,
      currentUserId: () => actor,
    );

    expect(
      (await repository.save(
        userId: 'user-a',
        companyId: 'company-a',
      )).failureOrNull,
      isNull,
    );
    actor = 'user-b';
    expect((await repository.read('user-b')).dataOrNull, isNull);
    expect(
      (await repository.read('user-a')).failureOrNull?.code,
      CompanyFailureCodes.authRequired,
    );
    expect(
      (await repository.save(
        userId: 'user-b',
        companyId: 'company-b',
      )).failureOrNull,
      isNull,
    );
    expect((await repository.read('user-b')).dataOrNull, 'company-b');

    actor = 'user-a';
    expect((await repository.read('user-a')).dataOrNull, 'company-a');
    expect(local.values, {'user-a': 'company-a', 'user-b': 'company-b'});
  });

  test(
    'signed-out actor cannot read or write another tenant preference',
    () async {
      final local = _Local();
      final repository = SelectedCompanyPreferenceRepositoryImpl(
        localDataSource: local,
        currentUserId: () => null,
      );

      expect(
        (await repository.read('user-a')).failureOrNull?.code,
        CompanyFailureCodes.authRequired,
      );
      expect(
        (await repository.save(
          userId: 'user-a',
          companyId: 'company-a',
        )).failureOrNull?.code,
        CompanyFailureCodes.authRequired,
      );
      expect(local.values, isEmpty);
    },
  );

  test(
    'actor change and local read failure still returns auth denial',
    () async {
      var actor = 'user-a';
      final pending = Completer<String?>();
      final repository = SelectedCompanyPreferenceRepositoryImpl(
        localDataSource: _Local()..pendingRead = pending,
        currentUserId: () => actor,
      );

      final read = repository.read('user-a');
      actor = 'user-b';
      pending.completeError(StateError('hidden storage error'));
      final result = await read;
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
      expect(result.dataOrNull, isNull);
    },
  );

  test(
    'actor change and local write failure never returns stored success',
    () async {
      var actor = 'user-a';
      final local = _Local()..delayWrites = true;
      final repository = SelectedCompanyPreferenceRepositoryImpl(
        localDataSource: local,
        currentUserId: () => actor,
      );

      final write = repository.save(userId: 'user-a', companyId: 'company-a');
      await Future<void>.delayed(Duration.zero);
      actor = 'user-b';
      local.waitingWrites.single.completeError(StateError('storage failed'));
      final result = await write;
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
      expect(local.values, isEmpty);
    },
  );

  test('blank company ID is a validation failure, never auth denial', () async {
    final repository = SelectedCompanyPreferenceRepositoryImpl(
      localDataSource: _Local(),
      currentUserId: () => 'user-a',
    );
    final result = await repository.save(userId: 'user-a', companyId: ' ');
    expect(result.failureOrNull?.code, CompanyFailureCodes.companyNotAvailable);
  });

  test(
    'account change mid-read cannot return earlier user preference',
    () async {
      var actor = 'user-a';
      final pending = Completer<String?>();
      final local = _Local()..pendingRead = pending;
      final repository = SelectedCompanyPreferenceRepositoryImpl(
        localDataSource: local,
        currentUserId: () => actor,
      );

      final read = repository.read('user-a');
      actor = 'user-b';
      pending.complete('company-a');
      final result = await read;

      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
    },
  );

  test('overlapping preference writes keep last requested selection', () async {
    final local = _Local()..delayWrites = true;
    final repository = SelectedCompanyPreferenceRepositoryImpl(
      localDataSource: local,
      currentUserId: () => 'user-a',
    );

    final first = repository.save(userId: 'user-a', companyId: 'company-a');
    await Future<void>.delayed(Duration.zero);
    final second = repository.save(userId: 'user-a', companyId: 'company-b');
    await Future<void>.delayed(Duration.zero);
    expect(local.waitingWrites, hasLength(1));

    local.waitingWrites[0].complete();
    await first;
    await Future<void>.delayed(Duration.zero);
    expect(local.waitingWrites, hasLength(2));
    local.waitingWrites[1].complete();
    await second;
    expect(local.values['user-a'], 'company-b');
  });

  test(
    'secure storage failures are typed and contain no raw message',
    () async {
      final local = _Local()..throwOnRead = true;
      final repository = SelectedCompanyPreferenceRepositoryImpl(
        localDataSource: local,
        currentUserId: () => 'user-a',
      );
      final read = await repository.read('user-a');
      expect(read.failureOrNull, isA<UnexpectedFailure>());
      expect(read.failureOrNull?.message, isNull);

      local.throwOnRead = false;
      local.throwOnWrite = true;
      final write = await repository.save(
        userId: 'user-a',
        companyId: 'company-a',
      );
      expect(write.failureOrNull, isA<UnexpectedFailure>());
      expect(write.failureOrNull?.message, isNull);
    },
  );
}

final class _Local implements SelectedCompanyPreferenceLocalDataSource {
  final Map<String, String> values = {};
  final List<Completer<void>> waitingWrites = [];
  Completer<String?>? pendingRead;
  bool delayWrites = false;
  bool throwOnRead = false;
  bool throwOnWrite = false;

  @override
  Future<String?> read(String userId) async {
    if (throwOnRead) throw StateError('private-storage-details');
    final pending = pendingRead;
    if (pending != null) return pending.future;
    return values[userId];
  }

  @override
  Future<void> write(String userId, String companyId) async {
    if (throwOnWrite) throw StateError('private-storage-details');
    if (delayWrites) {
      final pending = Completer<void>();
      waitingWrites.add(pending);
      await pending.future;
    }
    values[userId] = companyId;
  }
}
