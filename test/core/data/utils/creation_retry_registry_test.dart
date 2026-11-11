import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/data/utils/creation_retry_registry.dart';

void main() {
  test('retries of identical payload retain their creation request identity', () {
    final registry = CreationRetryRegistry();
    final first = registry.keyFor({'company_id': 'company', 'notes': 'draft'});
    final replay = registry.keyFor({'notes': 'draft', 'company_id': 'company'});
    expect(replay, first);

    registry.markSucceeded({'company_id': 'company', 'notes': 'draft'});
    expect(registry.keyFor({'company_id': 'company', 'notes': 'draft'}), isNot(first));
  });

  test('independent payloads cannot reuse the same request identity', () {
    final registry = CreationRetryRegistry();
    final first = registry.keyFor({'company_id': 'company-a', 'id': 'x'});
    final second = registry.keyFor({'company_id': 'company-b', 'id': 'x'});
    expect(second, isNot(first));
  });
}
