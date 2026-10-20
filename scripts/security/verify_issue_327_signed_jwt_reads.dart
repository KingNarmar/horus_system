// Issue #327 signed-JWT HTTP read-only security verification.
// This is a Development-only, credential-free-in-repository test harness.
// Run with real role-specific users. No requests modify business data.
//
// Required environment: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY,
// HORUS_327_COMPANY_A_ID, HORUS_327_COMPANY_B_ID.
// Run all: dart run scripts/security/verify_issue_327_signed_jwt_reads.dart
// Run one: dart run scripts/security/verify_issue_327_signed_jwt_reads.dart --role=owner
//
// Each account must be active in exactly one of the two test companies, and
// not a member of the other. Existing priced Trips/Routes are required for positive
// finance-read assertions. No passwords, JWTs, amounts or responses are logged.

import 'dart:convert';
import 'dart:io';

const _devHost = 'zwnfmszssxtfxkaofnhq.supabase.co';
const _roles = [
  'owner',
  'admin',
  'accountant',
  'operations',
  'viewer',
  'driver',
];
const _tripMoney = [
  'freight_price',
  'agreed_freight_rate_per_ton',
  'total_expenses',
];
const _routeMoney = ['default_freight_price'];
final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

class _Reply {
  final int status;
  final Object? body;

  const _Reply(this.status, this.body);

  bool get ok => status >= 200 && status < 300;
}

class _Api {
  final Uri base;
  final String publishableKey;
  final HttpClient _client = HttpClient();

  _Api(this.base, this.publishableKey);

  Future<_Reply> send(
    String method,
    String path, {
    String? jwt,
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = base.resolve(path).replace(queryParameters: query);
    final request = await _client.openUrl(method, uri);
    request.headers.set('apikey', publishableKey);
    request.headers.set('Accept', 'application/json');
    if (jwt != null) {
      request.headers.set('Authorization', 'Bearer $jwt');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final responseText = await utf8.decoder.bind(response).join();
    Object? parsed;
    try {
      parsed = jsonDecode(responseText);
    } on FormatException {
      parsed = null;
    }
    return _Reply(response.statusCode, parsed);
  }

  Future<_Reply> table(
    String name,
    Map<String, String> query, {
    String? jwt,
  }) =>
      send('GET', '/rest/v1/$name', query: query, jwt: jwt);

  Future<_Reply> rpc(String name, String companyId, {String? jwt}) =>
      send(
        'POST',
        '/rest/v1/rpc/$name',
        jwt: jwt,
        body: {'p_company_id': companyId},
      );

  void close() => _client.close(force: true);
}

class _Results {
  int passed = 0;
  int failed = 0;
  int skipped = 0;

  Future<void> check(String label, Future<bool> Function() action) async {
    try {
      if (await action()) {
        passed++;
        stdout.writeln('PASS  $label');
      } else {
        failed++;
        stdout.writeln('FAIL  $label');
      }
    } catch (_) {
      failed++;
      stdout.writeln('FAIL  $label (request error; details suppressed)');
    }
  }

  void skip(String label) {
    skipped++;
    stdout.writeln('SKIP  $label');
  }

  void finish() {
    stdout.writeln(
      'SUMMARY: $passed PASS / $failed FAIL / $skipped SKIP',
    );
    if (failed > 0 || skipped > 0) exitCode = 1;
  }
}

String _requiredEnv(String name) {
  final value = Platform.environment[name]?.trim() ?? '';
  if (value.isEmpty) {
    throw StateError('Missing environment variable: $name');
  }
  return value;
}

String? _readEmail(String role) {
  stdout.write('$role test account email (blank to skip): ');
  final value = stdin.readLineSync()?.trim();
  return value == null || value.isEmpty ? null : value;
}

String _readPassword() {
  if (!stdin.hasTerminal) {
    throw StateError('Interactive terminal required for secure password entry.');
  }
  stdout.write('Password (input hidden): ');
  final previousEcho = stdin.echoMode;
  try {
    stdin.echoMode = false;
    return stdin.readLineSync() ?? '';
  } finally {
    stdin.echoMode = previousEcho;
    stdout.writeln();
  }
}

bool _rowsAreCompanyScoped(_Reply reply, String companyId) {
  if (!reply.ok || reply.body is! List) return false;
  return (reply.body! as List).every(
    (record) => record is Map && record['company_id'] == companyId,
  );
}

bool _operationalRead(_Reply reply, String companyId, bool driver) {
  if (!_rowsAreCompanyScoped(reply, companyId)) return false;
  final rows = reply.body! as List;
  return driver ? rows.isEmpty : rows.isNotEmpty;
}

bool _directDenied(_Reply reply) =>
    (reply.status == 401 || reply.status == 403) &&
    reply.body is Map &&
    (reply.body! as Map)['code'] == '42501';

bool _rpcDenied(_Reply reply, String rpcName) {
  final expectedCode = switch (rpcName) {
    'get_authorized_trip_records' => 'P3433',
    'get_authorized_route_records' => 'P3434',
    _ => null,
  };
  return expectedCode != null &&
      !reply.ok &&
      reply.body is Map &&
      (reply.body! as Map)['code'] == expectedCode;
}

bool _projectionAllowed(
  _Reply reply,
  String companyId,
  bool finance,
  List<String> moneyKeys,
) {
  if (!_rowsAreCompanyScoped(reply, companyId)) return false;
  final rows = reply.body! as List;
  if (rows.isEmpty) return false; // Must verify against nonempty fixture.
  final objects = rows.cast<Map>();
  if (objects.any((row) => moneyKeys.any((key) => !row.containsKey(key)))) {
    return false; // Flutter mapper contract.
  }
  if (!finance) {
    return objects.every(
      (row) => moneyKeys.every((key) => row[key] == null),
    );
  }
  return objects.any(
    (row) => moneyKeys.any((key) => row[key] != null),
  ); // Positive financial visibility must be demonstrated.
}

Future<String?> _activeCompanyForRole(
  _Api api,
  String jwt,
  String userId,
  String expectedRole,
  String companyAId,
  String companyBId,
) async {
  final reply = await api.table('company_users', {
    'select': 'role,is_active,company_id',
    'user_id': 'eq.$userId',
  }, jwt: jwt);
  if (!reply.ok || reply.body is! List) return null;

  final members = (reply.body! as List).whereType<Map>().where(
    (row) => row['is_active'] == true,
  ).toList();
  final expected = members.where(
    (row) =>
        row['role'] == expectedRole &&
        (row['company_id'] == companyAId ||
            row['company_id'] == companyBId),
  ).toList();
  if (expected.length != 1) return null;

  final companyId = expected.single['company_id'] as String;
  final foreignId = companyId == companyAId ? companyBId : companyAId;
  if (members.any((row) => row['company_id'] == foreignId)) {
    return null; // A cross-tenant negative test requires no foreign membership.
  }
  return companyId;
}

Future<void> _checkRole(
  _Api api,
  _Results results,
  String role,
  String companyAId,
  String companyBId,
) async {
  final email = _readEmail(role);
  if (email == null) {
    results.skip('$role signed-JWT test user missing');
    return;
  }
  final password = _readPassword();
  final auth = await api.send(
    'POST',
    '/auth/v1/token',
    query: {'grant_type': 'password'},
    body: {'email': email, 'password': password},
  );
  if (!auth.ok || auth.body is! Map) {
    results.failed++;
    stdout.writeln('FAIL  $role login (HTTP ${auth.status})');
    return;
  }
  final session = auth.body! as Map;
  final jwt = session['access_token'];
  final user = session['user'];
  if (jwt is! String || jwt.isEmpty || user is! Map || user['id'] is! String) {
    results.failed++;
    stdout.writeln('FAIL  $role session missing signed user JWT');
    return;
  }
  final companyId = await _activeCompanyForRole(
    api,
    jwt,
    user['id'] as String,
    role,
    companyAId,
    companyBId,
  );
  if (companyId == null) {
    results.failed++;
    stdout.writeln(
      'FAIL  $role role or company membership unsuitable for isolation test',
    );
    return;
  }
  final foreignCompanyId =
      companyId == companyAId ? companyBId : companyAId;
  results.passed++;
  stdout.writeln('PASS  $role active role and tenant verified on server');

  final finance = role == 'owner' || role == 'admin' || role == 'accountant';
  final driver = role == 'driver';
  for (final table in ['trips', 'routes']) {
    await results.check('$role $table operational REST', () async {
      final response = await api.table(table, {
        'select': 'id,company_id',
        'company_id': 'eq.$companyId',
        'limit': '2',
      }, jwt: jwt);
      return _operationalRead(response, companyId, driver);
    });
  }

  for (final entry in {
    'trips': _tripMoney,
    'routes': _routeMoney,
  }.entries) {
    for (final field in entry.value) {
      await results.check('$role direct ${entry.key}.$field denied', () async {
        final response = await api.table(entry.key, {
          'select': field,
          'company_id': 'eq.$companyId',
          'limit': '1',
        }, jwt: jwt);
        return _directDenied(response);
      });
    }
  }

  for (final entry in {
    'get_authorized_trip_records': _tripMoney,
    'get_authorized_route_records': _routeMoney,
  }.entries) {
    await results.check('$role ${entry.key} projection', () async {
      final response = await api.rpc(entry.key, companyId, jwt: jwt);
      return driver
          ? _rpcDenied(response, entry.key)
          : _projectionAllowed(response, companyId, finance, entry.value);
    });
    await results.check('$role ${entry.key} foreign tenant denial', () async {
      final response = await api.rpc(
        entry.key,
        foreignCompanyId,
        jwt: jwt,
      );
      return _rpcDenied(response, entry.key);
    });
  }

  for (final table in ['trips', 'routes']) {
    await results.check('$role $table foreign REST isolation', () async {
      final response = await api.table(table, {
        'select': 'id,company_id',
        'company_id': 'eq.$foreignCompanyId',
        'limit': '1',
      }, jwt: jwt);
      return response.ok && response.body is List &&
          (response.body! as List).isEmpty;
    });
  }
}

Future<void> main(List<String> args) async {
  if (args.length > 1 ||
      (args.isNotEmpty && !args.single.startsWith('--role='))) {
    stderr.writeln('Usage: verify_issue_327_signed_jwt_reads.dart [--role=<role>]');
    exitCode = 64;
    return;
  }
  final selectedRole = args.isEmpty ? null : args.single.substring(7);
  if (selectedRole != null && !_roles.contains(selectedRole)) {
    stderr.writeln('Unknown test role. Use one of: ${_roles.join(', ')}');
    exitCode = 64;
    return;
  }

  final url = Uri.parse(_requiredEnv('SUPABASE_URL'));
  if (url.scheme != 'https' || url.host != _devHost ||
      (url.path.isNotEmpty && url.path != '/') ||
      url.hasQuery || url.hasFragment) {
    throw StateError('Refusing any target other than H.O.R.U.S Development.');
  }
  final key = _requiredEnv('SUPABASE_PUBLISHABLE_KEY');
  final companyAId = _requiredEnv('HORUS_327_COMPANY_A_ID');
  final companyBId = _requiredEnv('HORUS_327_COMPANY_B_ID');
  if (!_uuidPattern.hasMatch(companyAId) ||
      !_uuidPattern.hasMatch(companyBId) ||
      companyAId.toLowerCase() == companyBId.toLowerCase()) {
    throw StateError('Valid, distinct Development company UUIDs required.');
  }
  if (!stdin.hasTerminal) {
    throw StateError('Must run interactively, not in CI or captured logs.');
  }

  final api = _Api(url, key);
  final results = _Results();
  try {
    await results.check('anonymous Trip projection denied', () async =>
        _directDenied(await api.table('trips', {
          'select': 'freight_price',
          'limit': '1',
        })));
    await results.check('anonymous Trip RPC denied', () async {
      final response = await api.rpc('get_authorized_trip_records', companyAId);
      return response.status == 401 || response.status == 403;
    });
    for (final role in _roles) {
      if (selectedRole != null && role != selectedRole) continue;
      try {
        await _checkRole(api, results, role, companyAId, companyBId);
      } catch (_) {
        results.failed++;
        stdout.writeln('FAIL  $role unexpected request error (details suppressed)');
      }
    }
  } finally {
    api.close();
  }
  results.finish();
}
