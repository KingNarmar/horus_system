import 'package:horus_system/features/company/data/services/company_creation_request_identity.dart';
import 'package:test/test.dart';

void main() {
  final parameters = <String, Object?>{
    'p_name': 'Horus Transport',
    'p_business_timezone': 'Asia/Dubai',
  };

  test('retry of an unchanged request retains the same valid UUID', () {
    final identity = CompanyCreationRequestIdentity();
    final first = identity.getOrCreate(parameters);
    final second = identity.getOrCreate(Map.of(parameters));
    expect(first, second);
    expect(first, matches(RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    )));
  });

  test('changed request is an independent creation intent', () {
    final identity = CompanyCreationRequestIdentity();
    final first = identity.getOrCreate(parameters);
    final second = identity.getOrCreate({
      ...parameters,
      'p_name': 'Another Company',
    });
    expect(first, isNot(second));
  });

  test('successful completion releases the old identity', () {
    final identity = CompanyCreationRequestIdentity();
    final first = identity.getOrCreate(parameters);
    identity.complete('different-request-id');
    expect(identity.getOrCreate(parameters), first);
    identity.complete(first);
    expect(identity.getOrCreate(parameters), isNot(first));
  });
}
