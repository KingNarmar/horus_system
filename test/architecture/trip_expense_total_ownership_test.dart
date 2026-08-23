import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trip expense total maintenance stays DB-owned', () {
    final dataSource = File(
      'lib/features/expenses/data/datasources/'
      'trip_expenses_remote_data_source.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/expenses/data/repositories/trip_expense_repo_impl.dart',
    ).readAsStringSync();

    expect(dataSource, isNot(contains('recalculateTripTotalExpenses')));
    expect(repository, isNot(contains('recalculateTripTotalExpenses')));
    expect(dataSource, contains('getTripTotalExpenses'));
    expect(repository, contains('getTripTotalExpenses'));
    expect(
      dataSource,
      isNot(contains('DbTimestamp.nowUtcIsoString()')),
      reason:
          'Trip expense Data must not write the derived trips.total_expenses cache.',
    );
  });
}
