// Issue #317 R4.4: TWO signed user sessions, Development only.
// This tool creates ONE QA settlement, races draft creation and Finalize/Void,
// and verifies persisted rows and the linked audit. It is NOT a transaction
// rollback. A failure may leave a QA draft/finalized settlement to void manually.
//
// Required: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, two company fixture IDs,
// HORUS_317_R44_QA_DRIVER_ID (must be the "sync test" driver in Company A).
//
// dart run scripts/security/verify_issue_317_r44_signed_jwt_concurrency.dart --preflight
// dart run scripts/security/verify_issue_317_r44_signed_jwt_concurrency.dart --execute

import 'dart:io';

import 'issue_317_r44_concurrent_fixture.dart';
import 'issue_317_r44_dev_test_client.dart';

const _maxFixtureRows = 500;

String _requiredQaDriver() {
  final value = Platform.environment['HORUS_317_R44_QA_DRIVER_ID']?.trim() ?? '';
  if (!isR44Uuid(value)) {
    throw const FormatException('HORUS_317_R44_QA_DRIVER_ID must be a QA UUID.');
  }
  return value;
}

Future<List<Map<String, dynamic>>> _read(
  R44DevClient client,
  String jwt,
  String table,
  Map<String, String> query,
) async {
  final rows = (await client.request(
    'GET',
    '/rest/v1/$table',
    jwt: jwt,
    query: {...query, 'limit': '$_maxFixtureRows'},
  )).rows;
  if (rows.length == _maxFixtureRows) {
    throw StateError('QA read may be truncated; unsafe to proceed.');
  }
  return rows;
}

Future<R44ConcurrentFixture> _loadFixture(
  R44DevClient client,
  R44Session session,
  String driverId,
) async {
  final companyId = session.companyId;
  final companies = await _read(client, session.jwt, 'companies', {
    'select': 'id,base_currency_code,base_currency_fraction_digits',
    'id': 'eq.$companyId',
  });
  final drivers = await _read(client, session.jwt, 'drivers', {
    'select': 'id,company_id,full_name,is_active',
    'company_id': 'eq.$companyId',
    'id': 'eq.$driverId',
  });
  if (companies.length != 1 || drivers.length != 1) {
    throw StateError('Company or QA driver missing.');
  }

  final revisions = await _read(
    client,
    session.jwt,
    'driver_compensation_revisions',
    {
      'select': 'id,company_id,driver_id,effective_from,effective_to,'
          'currency_code,currency_fraction_digits,amount_minor_units',
      'company_id': 'eq.$companyId',
      'driver_id': 'eq.$driverId',
    },
  );
  // Inspect all historical movements, not just the target period. This test
  // intentionally supports only a fixture with a verified zero balance.
  final movements = await _read(
    client,
    session.jwt,
    'driver_financial_movements',
    {
      'select': 'id',
      'company_id': 'eq.$companyId',
      'driver_id': 'eq.$driverId',
    },
  );
  final trips = await _read(client, session.jwt, 'trips', {
    'select': 'id',
    'company_id': 'eq.$companyId',
    'driver_id': 'eq.$driverId',
  });

  final expenses = <Map<String, dynamic>>[];
  if (trips.isNotEmpty) {
    final ids = trips.map((row) => row['id']?.toString() ?? '').toList();
    if (ids.any((id) => !isR44Uuid(id))) {
      throw StateError('Non-UUID QA trip record.');
    }
    // The bounded fixture must not own too many trips for one safe query.
    if (ids.length > 100) throw StateError('QA trip set too large.');
    expenses.addAll(await _read(client, session.jwt, 'expense_ledger_entries', {
      'select': 'id',
      'company_id': 'eq.$companyId',
      'trip_id': 'in.(' + ids.join(',') + ')',
      'funding_source': 'in.(driver_advance,driver_cash)',
      'is_voided': 'eq.false',
    }));
  }

  final settlements = await _read(client, session.jwt, 'driver_settlements', {
    'select': 'id,period_start,period_end,status,notes',
    'company_id': 'eq.$companyId',
    'driver_id': 'eq.$driverId',
  });
  final fixture = R44ConcurrentFixture.fromVerifiedRows(
    companyId: companyId,
    driverId: driverId,
    company: companies.single,
    driver: drivers.single,
    revisions: revisions,
    movements: movements,
    driverFundedExpenses: expenses,
    settlements: settlements,
  );
  if (fixture == null) {
    throw StateError('QA fixture financial preconditions no longer match.');
  }
  return fixture;
}

Future<List<Map<String, dynamic>>> _settlementRows(
  R44DevClient client,
  R44Session session,
  String settlementId,
) => _read(client, session.jwt, 'driver_settlements', {
  'select': 'id,status,notes,void_reason,period_start,period_end',
  'company_id': 'eq.' + session.companyId,
  'id': 'eq.$settlementId',
});

Future<List<Map<String, dynamic>>> _auditRows(
  R44DevClient client,
  R44Session session,
  String driverId,
) => _read(client, session.jwt, 'audit_logs', {
  'select': 'action,metadata',
  'company_id': 'eq.' + session.companyId,
  'module': 'eq.drivers',
  'entity_type': 'eq.driver',
  'entity_id': 'eq.$driverId',
});

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      !{'--preflight', '--execute'}.contains(args.single)) {
    stderr.writeln('Usage: --preflight | --execute');
    exitCode = 64;
    return;
  }
  R44DevClient? owner;
  R44DevClient? admin;
  try {
    final config = R44DevConfig.fromEnvironment();
    final driverId = _requiredQaDriver();
    if (!stdin.hasTerminal) throw StateError('Interactive terminal required.');
    if (args.single == '--preflight') {
      stdout.writeln('PASS  Development-only bounded concurrency preflight.');
      stdout.writeln('No network requests or database changes performed.');
      return;
    }
    stdout.writeln(
      'DEVELOPMENT QA WRITE: one Draft then concurrent Finalize/Void. '
      'An auditable Voided row remains afterward.',
    );
    final confirmation = r44Prompt(
      'Type R44 DEVELOPMENT RACE to authorize this fixture: ',
    );
    if (confirmation != 'R44 DEVELOPMENT RACE') {
      throw StateError('Execution not confirmed.');
    }

    owner = R44DevClient(config);
    admin = R44DevClient(config);
    final ownerEmail = r44Prompt('Owner Development test email: ');
    if (ownerEmail.isEmpty) throw StateError('Owner missing.');
    final first = await owner.loginForRole(
      role: 'owner',
      email: ownerEmail,
      password: r44Password(),
      requireCompanyA: true,
    );
    final adminEmail = r44Prompt('Admin Development test email: ');
    if (adminEmail.isEmpty) throw StateError('Admin missing.');
    final second = await admin.loginForRole(
      role: 'admin',
      email: adminEmail,
      password: r44Password(),
      requireCompanyA: true,
    );
    if (first.userId == second.userId ||
        first.companyId != second.companyId) {
      throw StateError('Two different authorized same-company users required.');
    }
    final fixture = await _loadFixture(owner, first, driverId);
    stdout.writeln('PASS  isolated zero-source financial QA fixture verified.');

    final attempts = await Future.wait([
      owner.request(
        'POST',
        '/rest/v1/rpc/create_driver_settlement_draft_atomic',
        jwt: first.jwt,
        data: fixture.requestBody(),
      ),
      admin.request(
        'POST',
        '/rest/v1/rpc/create_driver_settlement_draft_atomic',
        jwt: second.jwt,
        data: fixture.requestBody(),
      ),
    ]);
    final settlementId = attempts.first.body;
    if (settlementId is! String || !isR44Uuid(settlementId)) {
      throw StateError('Racing creation failed; check QA records before retry.');
    }
    var rows = await _settlementRows(owner, first, settlementId);
    var audit = await _auditRows(owner, first, driverId);
    if (!r44RaceCreatedOnce(
      first: attempts[0],
      second: attempts[1],
      records: rows,
      audit: audit,
    )) {
      stderr.writeln(
        'FAIL  duplicate-Draft race; a QA row might require manual Void. '
        'Do not retry blindly.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('PASS  concurrent Draft: same ID, one row, one create audit.');

    final updateQuery = {
      'company_id': 'eq.' + fixture.companyId,
      'id': 'eq.$settlementId',
    };
    final changes = await Future.wait([
      owner.request(
        'PATCH',
        '/rest/v1/driver_settlements',
        jwt: first.jwt,
        query: updateQuery,
        data: {'status': 'finalized'},
      ),
      admin.request(
        'PATCH',
        '/rest/v1/driver_settlements',
        jwt: second.jwt,
        query: updateQuery,
        data: {'status': 'voided', 'void_reason': r44QaVoidReason},
      ),
    ]);
    rows = await _settlementRows(owner, first, settlementId);
    audit = await _auditRows(owner, first, driverId);
    final passed = r44RaceVoidedOnce(
      finalizeReply: changes[0],
      voidReply: changes[1],
      records: rows,
      audit: audit,
      settlementId: settlementId,
    );
    stdout.writeln(passed
        ? 'PASS  Finalize/Void race: one voided QA row, audit consistent.'
        : 'FAIL  Finalize/Void race; review QA row before retry.');
    if (!passed) exitCode = 1;
    stdout.writeln('SUMMARY: ' + (passed ? '3 PASS / 0 FAIL' : '2 PASS / 1 FAIL'));
  } catch (_) {
    stderr.writeln(
      'BLOCKED — QA fixture/session/race invalid. No Production request made. '
      'If --execute began, inspect any QA Draft before retrying. '
      'Credentials and raw server errors suppressed.',
    );
    exitCode = 1;
  } finally {
    owner?.close();
    admin?.close();
  }
}
