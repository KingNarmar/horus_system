// Issue #317 R4.4: Development-only source-backed financial race.
// Different signed-in Owner and Admin accounts race expense void vs settlement
// finalization. Does NOT create or repair QA data; one fixture is consumed.
// No Production access, no privileged keys, no automatic cleanup.
//
// Required client env: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY,
// HORUS_317_COMPANY_A_ID/B_ID (or existing HORUS_327_COMPANY_A_ID/B_ID).
// Fixture env: HORUS_317_R44_SOURCE_EXPENSE_ID, _SOURCE_SETTLEMENT_ID,
// _SOURCE_DRIVER_ID, _SOURCE_MARKER.
//
// dart run scripts/security/verify_issue_317_r44_source_void_finalize.dart --preflight
// dart run scripts/security/verify_issue_317_r44_source_void_finalize.dart --execute

import 'dart:io';

import 'issue_317_r44_dev_test_client.dart';
import 'issue_317_r44_source_race_contract.dart';

final class _FixtureEnv {
  final R44SourceRaceFixture fixture;

  _FixtureEnv(R44DevConfig config)
      : fixture = R44SourceRaceFixture(
          companyId: config.companyA,
          expenseId: _required('HORUS_317_R44_SOURCE_EXPENSE_ID'),
          settlementId: _required('HORUS_317_R44_SOURCE_SETTLEMENT_ID'),
          driverId: _required('HORUS_317_R44_SOURCE_DRIVER_ID'),
          marker: _required('HORUS_317_R44_SOURCE_MARKER'),
        ) {
    if (!fixture.valid) throw StateError('Invalid isolated QA fixture.');
  }

  static String _required(String name) {
    final value = Platform.environment[name]?.trim() ?? '';
    if (value.isEmpty) throw StateError('QA fixture missing.');
    return value;
  }
}

Future<List<Map<String, dynamic>>> _rows(
  R44DevClient client,
  String jwt,
  String table,
  Map<String, String> filters,
) async {
  final reply = await client.request(
    'GET',
    '/rest/v1/$table',
    jwt: jwt,
    query: {...filters, 'limit': '500'},
  );
  final rows = reply.rows;
  if (rows.length >= 500) throw StateError('Truncated source race read.');
  return rows;
}

Future<Map<String, dynamic>> _single(
  R44DevClient client,
  String jwt,
  String table,
  Map<String, String> filters,
) async {
  final rows = await _rows(client, jwt, table, filters);
  if (rows.length != 1) throw StateError('Missing isolated QA row.');
  return rows.single;
}

Future<Map<String, dynamic>> _expense(
  R44DevClient client,
  R44Session session,
  R44SourceRaceFixture fixture,
) => _single(client, session.jwt, 'expense_ledger_entries', {
  'select': 'id,company_id,driver_id,trip_id,description,origin_kind,'
      'funding_source,is_voided,amount_minor_units,expense_date',
  'company_id': 'eq.${fixture.companyId}',
  'id': 'eq.${fixture.expenseId}',
});

Future<Map<String, dynamic>> _settlement(
  R44DevClient client,
  R44Session session,
  R44SourceRaceFixture fixture,
) => _single(client, session.jwt, 'driver_settlements', {
  'select': 'id,company_id,driver_id,status,notes,period_start,period_end,'
      'compensation_revision_id,currency_code,currency_fraction_digits,'
      'gross_salary_minor_units,net_salary_payable_minor_units,'
      'opening_driver_balance_minor_units,closing_driver_balance_minor_units',
  'company_id': 'eq.${fixture.companyId}',
  'id': 'eq.${fixture.settlementId}',
});

Future<void> _verifyFixture(
  R44DevClient client,
  R44Session session,
  R44SourceRaceFixture fixture,
) async {
  final company = await _single(
    client,
    session.jwt,
    'companies',
    {'select': 'id,base_currency_code,base_currency_fraction_digits',
     'id': 'eq.${fixture.companyId}'},
  );
  final expense = await _expense(client, session, fixture);
  final settlement = await _settlement(client, session, fixture);
  final items = await _rows(client, session.jwt, 'driver_settlement_items', {
    'select': 'company_id,settlement_id,source_type,source_id,direction,'
        'amount_minor_units,currency_code,currency_fraction_digits',
    'company_id': 'eq.${fixture.companyId}',
    'settlement_id': 'eq.${fixture.settlementId}',
  });
  if (!fixture.matches(
    expense: expense,
    settlement: settlement,
    items: items,
    company: company,
  )) {
    throw StateError('Source-backed fixture contract rejected.');
  }
  final trip = await _single(client, session.jwt, 'trips', {
    'select': 'id,company_id,driver_id',
    'company_id': 'eq.${fixture.companyId}',
    'id': 'eq.${expense['trip_id']}',
  });
  if (trip['driver_id'] != fixture.driverId) {
    throw StateError('Source and settlement driver mismatch.');
  }
}

Future<int> _expenseVoidAudits(
  R44DevClient client,
  R44Session session,
  R44SourceRaceFixture fixture,
) async {
  final rows = await _rows(client, session.jwt, 'audit_logs', {
    'select': 'id',
    'company_id': 'eq.${fixture.companyId}',
    'module': 'eq.expenses',
    'entity_type': 'eq.expense_ledger_entry',
    'entity_id': 'eq.${fixture.expenseId}',
    'action': 'eq.voided',
  });
  return rows.length;
}

Future<int> _finalizeAudits(
  R44DevClient client,
  R44Session session,
  R44SourceRaceFixture fixture,
) async {
  final rows = await _rows(client, session.jwt, 'audit_logs', {
    'select': 'metadata',
    'company_id': 'eq.${fixture.companyId}',
    'module': 'eq.drivers',
    'entity_type': 'eq.driver',
    'entity_id': 'eq.${fixture.driverId}',
  });
  return rows.where((row) {
    final metadata = row['metadata'];
    return metadata is Map &&
        metadata['settlement_id'] == fixture.settlementId &&
        metadata['audit_event'] == 'driver_settlement_finalized';
  }).length;
}

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      !{'--preflight', '--execute'}.contains(args.single)) {
    stderr.writeln('Usage: --preflight | --execute');
    exitCode = 64;
    return;
  }
  R44DevClient? ownerClient;
  R44DevClient? adminClient;
  try {
    final config = R44DevConfig.fromEnvironment();
    final fixture = _FixtureEnv(config).fixture;
    if (!stdin.hasTerminal) throw StateError('Interactive shell required.');
    if (args.single == '--execute') {
      stdout.writeln(
        'DEVELOPMENT FINANCIAL RACE: expense void vs Finalize. '
        'One fixture will be consumed; no automatic retry.',
      );
      final confirmation = r44Prompt(
        'Type EXECUTE R44 SOURCE RACE to authorize: ',
      );
      if (confirmation != 'EXECUTE R44 SOURCE RACE') {
        throw StateError('Execution was not approved.');
      }
    }

    ownerClient = R44DevClient(config);
    adminClient = R44DevClient(config);
    final ownerEmail = r44Prompt('Owner Development email: ');
    if (ownerEmail.isEmpty) throw StateError('Owner required.');
    final owner = await ownerClient.loginForRole(
      role: 'owner',
      email: ownerEmail,
      password: r44Password(),
      requireCompanyA: true,
    );
    final adminEmail = r44Prompt('Admin Development email: ');
    if (adminEmail.isEmpty) throw StateError('Admin required.');
    final admin = await adminClient.loginForRole(
      role: 'admin',
      email: adminEmail,
      password: r44Password(),
      requireCompanyA: true,
    );
    if (owner.userId == admin.userId || owner.companyId != admin.companyId) {
      throw StateError('Two different signed users in Company A required.');
    }

    await _verifyFixture(ownerClient, owner, fixture);
    final voidBefore = await _expenseVoidAudits(
      ownerClient,
      owner,
      fixture,
    );
    final finalizedBefore = await _finalizeAudits(
      ownerClient,
      owner,
      fixture,
    );
    if (voidBefore != 0 || finalizedBefore != 0) {
      throw StateError('This marked QA fixture has already been consumed.');
    }
    stdout.writeln('PASS  signed users and unconsumed source-backed QA fixture.');
    if (args.single == '--preflight') {
      stdout.writeln('SUMMARY: 1 PASS / 0 FAIL (read-only)');
      return;
    }

    final replies = await Future.wait([
      ownerClient.request(
        'POST',
        '/rest/v1/rpc/void_expense_ledger_entry',
        jwt: owner.jwt,
        data: {
          'p_company_id': fixture.companyId,
          'p_expense_id': fixture.expenseId,
          'p_reason': fixture.marker,
        },
      ),
      adminClient.request(
        'PATCH',
        '/rest/v1/driver_settlements',
        jwt: admin.jwt,
        query: {
          'company_id': 'eq.${fixture.companyId}',
          'id': 'eq.${fixture.settlementId}',
        },
        data: {'status': 'finalized'},
      ),
    ]);
    final expense = await _expense(ownerClient, owner, fixture);
    final settlement = await _settlement(ownerClient, owner, fixture);
    final voidAfter = await _expenseVoidAudits(
      ownerClient,
      owner,
      fixture,
    );
    final finalizedAfter = await _finalizeAudits(
      ownerClient,
      owner,
      fixture,
    );
    final outcome = verifyR44SourceRace(
      voidReply: replies[0],
      finalizeReply: replies[1],
      expense: expense,
      settlement: settlement,
      voidAuditDelta: voidAfter - voidBefore,
      finalizeAuditDelta: finalizedAfter - finalizedBefore,
    );
    switch (outcome) {
      case R44SourceRaceOutcome.voidWon:
        stdout.writeln(
          'PASS  expense void won; stale finalize denied and Draft preserved.',
        );
      case R44SourceRaceOutcome.finalizeWon:
        stdout.writeln(
          'PASS  settlement finalized; captured expense void denied.',
        );
      case R44SourceRaceOutcome.rejected:
        stderr.writeln(
          'FAIL  financial source race invariant. Inspect fixture before retry.',
        );
        exitCode = 1;
        return;
    }
    stdout.writeln('SUMMARY: 2 PASS / 0 FAIL');
  } catch (_) {
    stderr.writeln(
      'BLOCKED — fixture, authentication or race validation failed. '
      'If execution started, inspect persistent QA state before retrying. '
      'Secrets and raw financial responses suppressed.',
    );
    exitCode = 1;
  } finally {
    ownerClient?.close();
    adminClient?.close();
  }
}
