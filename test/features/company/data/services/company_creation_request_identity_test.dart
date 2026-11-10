import 'package:horus_system/features/company/data/datasources/company_creation_request_local_data_source.dart';
import 'package:horus_system/features/company/data/services/company_creation_request_identity.dart';
import 'package:test/test.dart';

final class _FakeLocalStore implements CompanyCreationRequestLocalDataSource {
  final values = <String, String>{};
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<String?> read(String userId) async {
    if (failReads) throw StateError('private local storage failure');
    return values[userId];
  }

  @override
  Future<void> write(String userId, String encodedRequest) async {
    if (failWrites) throw StateError('private local storage failure');
    values[userId] = encodedRequest;
  }

  @override
  Future<void> delete(String userId) async => values.remove(userId);
}

void main() {
  final parameters = <String, Object?>{
    'p_name': 'Horus Transport',
    'p_business_timezone': 'Asia/Dubai',
  };

  test('retry after app restart uses the original UUID', () async {
    final store = _FakeLocalStore();
    final first = await CompanyCreationRequestIdentity(
      store,
    ).getOrCreate(userId: 'user-1', parameters: parameters);
    final second = await CompanyCreationRequestIdentity(
      store,
    ).getOrCreate(userId: 'user-1', parameters: Map.of(parameters));
    expect(first, second);
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(store.values['user-1'], isNot(contains('Horus Transport')));
  });

  test('different actor cannot reuse the other account UUID', () async {
    final store = _FakeLocalStore();
    final service = CompanyCreationRequestIdentity(store);
    final first = await service.getOrCreate(
      userId: 'user-1',
      parameters: parameters,
    );
    final other = await service.getOrCreate(
      userId: 'user-2',
      parameters: parameters,
    );

    expect(other, isNot(first));
    expect(store.values.length, 2);
  });

  test(
    'unknown outcome with changed input retains the original UUID',
    () async {
      final store = _FakeLocalStore();
      final service = CompanyCreationRequestIdentity(store);
      final first = await service.getOrCreate(
        userId: 'user-1',
        parameters: parameters,
      );
      final changed = await service.getOrCreate(
        userId: 'user-1',
        parameters: {...parameters, 'p_name': 'Other Company'},
      );

      expect(changed, first);
    },
  );

  test('confirmed outcome clears UUID so new intent is independent', () async {
    final store = _FakeLocalStore();
    final service = CompanyCreationRequestIdentity(store);
    final first = await service.getOrCreate(
      userId: 'user-1',
      parameters: parameters,
    );
    await service.complete(userId: 'user-1', requestId: 'wrong-id');
    expect(
      await service.getOrCreate(userId: 'user-1', parameters: parameters),
      first,
    );
    await service.complete(userId: 'user-1', requestId: first);
    expect(
      await service.getOrCreate(userId: 'user-1', parameters: parameters),
      isNot(first),
    );
  });

  test('corrupted pending metadata fails closed', () async {
    final store = _FakeLocalStore();
    store.values['user-1'] = '{invalid-json';
    final service = CompanyCreationRequestIdentity(store);

    await expectLater(
      service.getOrCreate(userId: 'user-1', parameters: parameters),
      throwsA(isA<CompanyCreationRequestIdentityException>()),
    );
    expect(store.values['user-1'], '{invalid-json');
  });

  test('unavailable secure storage fails before starting request', () async {
    final store = _FakeLocalStore()..failWrites = true;
    final service = CompanyCreationRequestIdentity(store);

    await expectLater(
      service.getOrCreate(userId: 'user-1', parameters: parameters),
      throwsA(isA<CompanyCreationRequestIdentityException>()),
    );
    expect(store.values, isEmpty);
  });
}
