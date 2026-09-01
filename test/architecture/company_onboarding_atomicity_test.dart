import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('company onboarding stays server-authoritative and RPC-owned', () {
    final dataSource = File(
      'lib/features/company/data/datasources/company_remote_data_source.dart',
    ).readAsStringSync();

    expect(dataSource, contains('CompanyRpcConstants.createCompany'));
    expect(dataSource, contains('.rpc('));
    expect(
      dataSource,
      isNot(contains('.insert(')),
      reason:
          'Company onboarding must not split company and initial Owner writes in Flutter.',
    );
    expect(
      dataSource,
      isNot(contains('auth.currentUser')),
      reason: 'The server must derive the onboarding actor from auth.uid().',
    );
    expect(
      dataSource,
      isNot(contains('CompanyRole.owner')),
      reason: 'The server must assign the initial Owner role authoritatively.',
    );
    expect(
      dataSource,
      isNot(contains('Random.secure')),
      reason: 'The database must generate the company id for atomic onboarding.',
    );
  });
}
