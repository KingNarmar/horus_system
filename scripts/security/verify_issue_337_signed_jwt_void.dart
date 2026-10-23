// Issue #337 — Development-only signed-JWT expense void verification.
// Run only with isolated, marked test rows AFTER migration staging.
// Case order: denied/foreign/locked/legacy first; available last (consumed).
// All requests use real signed user JWTs; credentials and data stay hidden.
//
// Env: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, HORUS_337_COMPANY_A_ID,
// HORUS_337_COMPANY_B_ID, HORUS_337_LOCKED_EXPENSE_ID,
// HORUS_337_LEGACY_EXPENSE_ID, HORUS_337_AVAILABLE_EXPENSE_ID,
// HORUS_337_FOREIGN_EXPENSE_ID, HORUS_337_FIXTURE_MARKER.
//
// dart run scripts/security/verify_issue_337_signed_jwt_void.dart \
//   --execute --case=locked --role=owner

import 'dart:convert';
import 'dart:io';

const _host = 'zwnfmszssxtfxkaofnhq.supabase.co';
const _finance = {'owner', 'admin', 'accountant'};
const _restricted = {'operations', 'viewer', 'driver'};
const _cases = {
  'locked',
  'legacy',
  'available',
  'denied',
  'foreign',
  'anonymous',
};
final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

final class _StartupRefusal implements Exception {
  final String reason;
  const _StartupRefusal(this.reason);
}

// Startup reasons name failed checks only. Never include environment values,
// credentials, signed JWTs, HTTP bodies or financial records in diagnostics.
String _env(String key) {
  final value = Platform.environment[key]?.trim() ?? '';
  if (value.isEmpty) throw _StartupRefusal('missing environment variable $key');
  return value;
}

final class _Fixture {
  final String tenantA;
  final String tenantB;
  final Map<String, String> ids;
  final String marker;

  _Fixture()
      : tenantA = _env('HORUS_337_COMPANY_A_ID'),
        tenantB = _env('HORUS_337_COMPANY_B_ID'),
        ids = {
          'locked': _env('HORUS_337_LOCKED_EXPENSE_ID'),
          'legacy': _env('HORUS_337_LEGACY_EXPENSE_ID'),
          'available': _env('HORUS_337_AVAILABLE_EXPENSE_ID'),
          'foreign': _env('HORUS_337_FOREIGN_EXPENSE_ID'),
        },
        marker = _env('HORUS_337_FIXTURE_MARKER') {
    if (![
          tenantA,
          tenantB,
          ...ids.values,
        ].every((value) => _uuid.hasMatch(value)) ||
        tenantA == tenantB ||
        ids.values.toSet().length != 4 ||
        marker.length < 8) {
      throw const _StartupRefusal('fixture identifiers or marker invalid');
    }
  }

  String company(String test) => test == 'foreign' ? tenantB : tenantA;

  String expense(String test) =>
      ids[test == 'denied' || test == 'anonymous' ? 'available' : test]!;
}

final class _TestCase {
  final String name;
  final String role;

  _TestCase(List<String> args)
      : name = args.length == 3 && args[1].startsWith('--case=')
            ? args[1].substring('--case='.length)
            : '',
        role = args.length == 3 && args[2].startsWith('--role=')
            ? args[2].substring('--role='.length)
            : '' {
    if (args.length != 3 ||
        !{'--execute', '--preflight'}.contains(args.first) ||
        !_cases.contains(name) ||
        !(_finance.contains(role) ||
            _restricted.contains(role) ||
            role == 'anonymous') ||
        (name == 'denied' && !_restricted.contains(role)) ||
        (name == 'anonymous' && role != 'anonymous') ||
        (!{'denied', 'anonymous'}.contains(name) &&
            !_finance.contains(role))) {
      throw const _StartupRefusal('invalid command arguments or role/case');
    }
  }

  String get expectedSqlState =>
      name == 'denied' || name == 'foreign' ? 'P2801' : 'P2811';
}

final class _Reply {
  final int status;
  final Object? body;
  const _Reply(this.status, this.body);

  bool get ok => status >= 200 && status < 300;
  String? get code {
    final value = body;
    return value is Map ? value['code']?.toString() : null;
  }

  List<Map<String, dynamic>> get rows {
    final value = body;
    if (value is! List) throw StateError('Malformed fixture response.');
    return value.map((item) {
      if (item is! Map) throw StateError('Malformed fixture row.');
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}

final class _Credentials {
  final String id;
  final String jwt;
  const _Credentials(this.id, this.jwt);
}

final class _Gateway {
  final Uri origin;
  final String publishableKey;
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  _Gateway(this.origin, this.publishableKey);

  Future<_Reply> send(
    String method,
    String path, {
    String? jwt,
    Map<String, String>? query,
    Map<String, Object?>? data,
  }) async {
    final url = origin.resolve(path).replace(queryParameters: query);
    if (url.scheme != 'https' || url.host != _host) {
      throw StateError('Production/out-of-fixture request refused.');
    }
    final request = await client.openUrl(method, url);
    request.headers.set('apikey', publishableKey);
    request.headers.set('Accept', 'application/json');
    if (jwt != null) request.headers.set('Authorization', 'Bearer $jwt');
    if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    final response = await request.close();
    final payload = await utf8.decoder.bind(response).join();
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      throw StateError('Non-JSON response refused.');
    }
    return _Reply(response.statusCode, decoded);
  }

  Future<_Credentials> login(String email, String password) async {
    final response = await send(
      'POST', '/auth/v1/token?grant_type=password',
      data: {'email': email, 'password': password},
    );
    final data = response.body;
    if (!response.ok || data is! Map ||
        data['access_token'] is! String ||
        data['user'] is! Map ||
        (data['user'] as Map)['id'] is! String) {
      throw StateError('Real signed Development login required.');
    }
    return _Credentials(
      (data['user'] as Map)['id'] as String,
      data['access_token'] as String,
    );
  }

  Future<List<Map<String, dynamic>>> rows(
    String jwt, String table, Map<String, String> filters,
  ) async {
    if (!{'company_users', 'expense_ledger_entries',
          'driver_settlement_items', 'driver_settlements', 'audit_logs'}
        .contains(table)) {
      throw StateError('Table not allowed.');
    }
    final response = await send(
      'GET', '/rest/v1/$table', jwt: jwt, query: filters,
    );
    if (!response.ok) throw StateError('Fixture read failed.');
    return response.rows;
  }

  void close() => client.close(force: true);
}

String _line(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync()?.trim() ?? '';
}

String _password() {
  stdout.write('Password (hidden): ');
  final echo = stdin.echoMode;
  try {
    stdin.echoMode = false;
    return stdin.readLineSync() ?? '';
  } finally {
    stdin.echoMode = echo;
    stdout.writeln();
  }
}

Future<bool> _hasRole(
  _Gateway gateway, _Credentials user, String company, String role,
) async {
  final rows = await gateway.rows(
    user.jwt, 'company_users',
    {
      'select': 'company_id,user_id,role,is_active',
      'user_id': 'eq.${user.id}',
    },
  );
  return rows.any((row) => row['company_id'] == company &&
      row['role'] == role && row['is_active'] == true);
}

Future<Map<String, dynamic>> _expense(
  _Gateway gateway, _Credentials user, String company, String id,
) async {
  final rows = await gateway.rows(
    user.jwt, 'expense_ledger_entries',
    {
      'select': 'id,company_id,trip_id,description,funding_source,'
          'origin_kind,origin_id,is_voided',
      'company_id': 'eq.$company',
      'id': 'eq.$id',
    },
  );
  if (rows.length != 1) throw StateError('Expected one isolated expense.');
  return rows.single;
}

Future<int> _voidAudits(
  _Gateway gateway, _Credentials user, String company, String id,
) async {
  return (await gateway.rows(user.jwt, 'audit_logs', {
    'select': 'id',
    'company_id': 'eq.$company',
    'entity_id': 'eq.$id',
    'action': 'eq.voided',
  })).length;
}

Future<bool> _captured(
  _Gateway gateway, _Credentials user, String company, String sourceId,
) async {
  final items = await gateway.rows(
    user.jwt, 'driver_settlement_items',
    {
      'select': 'settlement_id',
      'company_id': 'eq.$company',
      'source_type': 'eq.trip_expense',
      'source_id': 'eq.$sourceId',
    },
  );
  for (final item in items) {
    final settlements = await gateway.rows(
      user.jwt, 'driver_settlements',
      {
        'select': 'status',
        'company_id': 'eq.$company',
        'id': "eq.${item['settlement_id']}",
      },
    );
    if (settlements.any((row) => row['status'] == 'finalized')) return true;
  }
  return false;
}

Future<void> main(List<String> args) async {
  _Gateway? gateway;
  try {
    final test = _TestCase(args);
    final fixture = _Fixture();
    final origin = Uri.tryParse(_env('SUPABASE_URL'));
    final publishableKey = _env('SUPABASE_PUBLISHABLE_KEY');
    if (origin == null ||
        origin.scheme != 'https' ||
        origin.host != _host ||
        origin.path.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        origin.userInfo.isNotEmpty) {
      throw const _StartupRefusal('Development URL invalid');
    }
    if (!publishableKey.startsWith('sb_publishable_')) {
      throw const _StartupRefusal('Development publishable key format invalid');
    }
    if (!stdin.hasTerminal) {
      throw const _StartupRefusal('Dart stdin is not an interactive terminal');
    }
    if (args.first == '--preflight') {
      stdout.writeln(
        'PASS  Development-only startup checks (no network or mutation)',
      );
      return;
    }
    final confirmation = _line(
      'Type EXECUTE + fixture marker + case, separated by spaces: ',
    );
    if (confirmation !=
        'EXECUTE ${fixture.marker} ${test.name}') {
      throw StateError('Explicit approval/fixture mismatch.');
    }
    gateway = _Gateway(origin, publishableKey);
    final owner = await gateway.login(
      _line('Target-company Owner email: '), _password(),
    );
    final _Credentials? actor = test.role == 'anonymous'
        ? null
        : await gateway.login(
            _line('Actor ${test.role} email: '),
            _password(),
          );
    final company = fixture.company(test.name);
    final expenseId = fixture.expense(test.name);
    if (!await _hasRole(gateway, owner, company, 'owner') ||
        (actor != null &&
            !await _hasRole(gateway, actor, fixture.tenantA, test.role)) ||
        (test.name == 'foreign' &&
            actor != null &&
            await _hasRole(gateway, actor, company, test.role))) {
      throw StateError('Signed user role/tenant preflight failed.');
    }

    final before = await _expense(gateway, owner, company, expenseId);
    if (before['is_voided'] != false ||
        !before['description'].toString().contains(fixture.marker) ||
        before['trip_id'] == null ||
        !{'driver_cash', 'driver_advance'}.contains(before['funding_source'])) {
      throw StateError('Unapproved expense fixture.');
    }
    final source = test.name == 'legacy'
        ? before['origin_id']?.toString()
        : before['id']?.toString();
    if (source == null || !_uuid.hasMatch(source)) {
      throw StateError('Invalid source reference.');
    }
    final captured = await _captured(gateway, owner, company, source);
    if ((test.name == 'locked' || test.name == 'legacy') != captured) {
      throw StateError('Fixture settlement state mismatch.');
    }

    final oldAudits = await _voidAudits(gateway, owner, company, expenseId);
    final result = await gateway.send(
      'POST', '/rest/v1/rpc/void_expense_ledger_entry',
      jwt: actor?.jwt,
      data: {
        'p_company_id': company,
        'p_expense_id': expenseId,
        'p_reason': fixture.marker,
      },
    );
    final after = await _expense(gateway, owner, company, expenseId);
    final newAudits = await _voidAudits(gateway, owner, company, expenseId);
    final isAnonymousDenied = test.name == 'anonymous' &&
        !result.ok &&
        (result.status == 401 || result.status == 403) &&
        {'42501', 'P2801', 'PGRST301'}.contains(result.code);
    var passed = test.name == 'available'
        ? result.ok && after['is_voided'] == true &&
            newAudits == oldAudits + 1
        : !result.ok &&
            (isAnonymousDenied || result.code == test.expectedSqlState) &&
            after['is_voided'] == false &&
            newAudits == oldAudits;

    if (passed && test.name == 'available') {
      final retry = await gateway.send(
        'POST',
        '/rest/v1/rpc/void_expense_ledger_entry',
        jwt: actor?.jwt,
        data: {
          'p_company_id': company,
          'p_expense_id': expenseId,
          'p_reason': fixture.marker,
        },
      );
      final finalRow = await _expense(gateway, owner, company, expenseId);
      final finalAuditCount = await _voidAudits(
        gateway,
        owner,
        company,
        expenseId,
      );
      passed = !retry.ok &&
          retry.code == 'P2807' &&
          finalRow['is_voided'] == true &&
          finalAuditCount == newAudits;
    }

    stdout.writeln(
      '${passed ? 'PASS  ' : 'FAIL  '}${test.name}/${test.role}',
    );
    if (!passed) exitCode = 1;
  } on _StartupRefusal catch (error) {
    stderr.writeln(
      'BLOCKED startup — ${error.reason}. No network request sent.',
    );
    exitCode = 1;
  } catch (_) {
    stderr.writeln(
      'BLOCKED — Development fixture or signed-JWT verification failed. '
      'Sensitive details suppressed.',
    );
    exitCode = 1;
  } finally {
    gateway?.close();
  }
}
