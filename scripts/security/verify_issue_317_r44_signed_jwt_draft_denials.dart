// Issue #317 R4.4 — Development-only signed-JWT NEGATIVE write checks.
//
// All RPC requests contain an intentionally invalid header and no source
// items. They cannot create settlement rows or audit events. This verifies
// the live authorization boundary, NOT successful financial writes.
// Required env: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY,
// HORUS_317_COMPANY_A_ID/B_ID (fallback: HORUS_327_COMPANY_A_ID/B_ID).
//
// dart run scripts/security/verify_issue_317_r44_signed_jwt_draft_denials.dart --preflight --role=owner
// dart run scripts/security/verify_issue_317_r44_signed_jwt_draft_denials.dart --execute --role=owner

import 'dart:convert';
import 'dart:io';

const _devHost = 'zwnfmszssxtfxkaofnhq.supabase.co';
const _roles = {'owner', 'admin', 'accountant', 'operations', 'viewer', 'driver', 'anonymous'};
const _finance = {'owner', 'admin', 'accountant'};
const _timeout = Duration(seconds: 20);
final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String? expectedIssue317R44DraftSqlstate({
  required String role,
  required bool foreign,
}) {
  if (!_roles.contains(role)) return null;
  if (role == 'anonymous' || foreign || !_finance.contains(role)) {
    return 'P2813';
  }
  return 'P2814';
}

final class _Config {
  final Uri origin;
  final String key;
  final String companyA;
  final String companyB;

  const _Config(this.origin, this.key, this.companyA, this.companyB);

  factory _Config.fromEnvironment() {
    String required(String key, [String? fallback]) {
      final first = Platform.environment[key]?.trim();
      final second = fallback == null
          ? null
          : Platform.environment[fallback]?.trim();
      if (first != null && first.isNotEmpty) return first;
      if (second != null && second.isNotEmpty) return second;
      throw FormatException('Missing Development environment variable: $key');
    }

    final origin = Uri.tryParse(required('SUPABASE_URL'));
    if (origin == null ||
        origin.scheme != 'https' ||
        origin.host != _devHost ||
        (origin.path.isNotEmpty && origin.path != '/') ||
        origin.hasQuery ||
        origin.hasFragment ||
        origin.userInfo.isNotEmpty) {
      throw const FormatException('Invalid SUPABASE_URL (Development required).');
    }
    final key = required('SUPABASE_PUBLISHABLE_KEY');
    final companyA = required('HORUS_317_COMPANY_A_ID', 'HORUS_327_COMPANY_A_ID');
    final companyB = required('HORUS_317_COMPANY_B_ID', 'HORUS_327_COMPANY_B_ID');

    if (!key.startsWith('sb_publishable_')) {
      throw const FormatException('Invalid SUPABASE_PUBLISHABLE_KEY format.');
    }
    if (!_uuid.hasMatch(companyA) ||
        !_uuid.hasMatch(companyB) ||
        companyA.toLowerCase() == companyB.toLowerCase()) {
      throw const FormatException('Invalid or duplicate Development company IDs.');
    }
    return _Config(origin, key, companyA, companyB);
  }
}

final class _Reply {
  final int status;
  final Object? body;

  const _Reply(this.status, this.body);

  bool get successful => status >= 200 && status < 300;

  String? get code {
    final data = body;
    return data is Map ? data['code']?.toString() : null;
  }
}

final class _AuthSession {
  final String userId;
  final String jwt;
  final String ownCompany;
  final String foreignCompany;

  const _AuthSession(
    this.userId,
    this.jwt,
    this.ownCompany,
    this.foreignCompany,
  );
}

final class _DevGateway {
  final _Config config;
  final HttpClient _client = HttpClient()..connectionTimeout = _timeout;

  _DevGateway(this.config);

  Future<_Reply> request(
    String method,
    String path, {
    String? jwt,
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final target = config.origin.resolve(path).replace(queryParameters: query);
    if (target.scheme != 'https' || target.host != _devHost) {
      throw StateError('Non-Development request refused.');
    }

    final request = await _client.openUrl(method, target).timeout(_timeout);
    request.headers.set('apikey', config.key);
    request.headers.set('Accept', 'application/json');
    if (jwt != null) request.headers.set('Authorization', 'Bearer $jwt');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final reply = await request.close().timeout(_timeout);
    final responseText = await utf8.decoder.bind(reply).join().timeout(_timeout);
    Object? decoded;
    try {
      decoded = jsonDecode(responseText);
    } on FormatException {
      throw StateError('Non-JSON Development response.');
    }
    return _Reply(reply.statusCode, decoded);
  }

  Future<_AuthSession> login(String role, String email, String password) async {
    final loginReply = await request(
      'POST',
      '/auth/v1/token',
      query: {'grant_type': 'password'},
      body: {'email': email, 'password': password},
    );
    final body = loginReply.body;
    if (!loginReply.successful ||
        body is! Map ||
        body['access_token'] is! String ||
        body['user'] is! Map ||
        (body['user'] as Map)['id'] is! String) {
      throw StateError('Development sign-in failed.');
    }
    final jwt = body['access_token'] as String;
    final userId = (body['user'] as Map)['id'] as String;
    if (jwt.split('.').length != 3 || !_uuid.hasMatch(userId)) {
      throw StateError('Signed user fixture invalid.');
    }

    final membership = await request(
      'GET',
      '/rest/v1/company_users',
      jwt: jwt,
      query: {
        'select': 'company_id,user_id,role,is_active',
        'user_id': 'eq.$userId',
      },
    );
    if (!membership.successful || membership.body is! List) {
      throw StateError('Role fixture unreadable.');
    }
    final rows = (membership.body as List).whereType<Map>();
    final active = rows.where((row) => row['is_active'] == true).toList();
    final matching = active.where((row) =>
        row['role'] == role &&
        (row['company_id'] == config.companyA ||
            row['company_id'] == config.companyB)).toList();
    if (matching.length != 1) throw StateError('Role fixture ambiguous.');
    final own = matching.single['company_id'] as String;
    final foreign = own == config.companyA
        ? config.companyB
        : config.companyA;
    if (active.any((row) => row['company_id'] == foreign)) {
      throw StateError('Cross-company fixture ambiguous.');
    }
    return _AuthSession(userId, jwt, own, foreign);
  }

  Future<_Reply> deniedDraft(String companyId, {String? jwt}) {
    // Header never passes the RPC's status/company allowlist. It is an
    // intentionally rejected, non-mutating negative authorization probe.
    return request(
      'POST',
      '/rest/v1/rpc/create_driver_settlement_draft_atomic',
      jwt: jwt,
      body: {
        'p_company_id': companyId,
        'p_header': {
          'status': 'invalid_r44_test_probe',
        },
        'p_items': <Object>[],
      },
    );
  }

  void close() => _client.close(force: true);
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

Future<void> main(List<String> args) async {
  final mode = args.where((arg) => arg == '--preflight' || arg == '--execute').toList();
  final roles = args.where((arg) => arg.startsWith('--role=')).toList();
  if (mode.length != 1 || roles.length != 1 || args.length != 2) {
    stderr.writeln('Usage: --preflight|--execute --role=<approved role>');
    exitCode = 64;
    return;
  }
  final role = roles.single.substring('--role='.length);
  if (!_roles.contains(role)) {
    stderr.writeln('Unrecognized test role.');
    exitCode = 64;
    return;
  }

  _DevGateway? gateway;
  try {
    final config = _Config.fromEnvironment();
    if (!stdin.hasTerminal) {
      stderr.writeln('BLOCKED — Interactive terminal required. No network request sent.');
      exitCode = 1;
      return;
    }
    if (mode.single == '--preflight') {
      stdout.writeln('PASS  Development-only, negative write probe configured.');
      return;
    }
    stdout.writeln('Signed-JWT negative-only RPC probe. No settlement can be created.');
    gateway = _DevGateway(config);
    if (role == 'anonymous') {
      final reply = await gateway.deniedDraft(config.companyA);
      // The anonymous role has no EXECUTE grant: SQLSTATE 42501.
      final pass = !reply.successful &&
          {'42501', 'P2813', 'PGRST301'}.contains(reply.code);
      stdout.writeln(pass ? 'PASS  anonymous denied' : 'FAIL  anonymous denial');
      if (!pass) exitCode = 1;
      return;
    }

    final email = _line('$role Development test email: ');
    if (email.isEmpty) throw StateError('Role fixture required.');
    final session = await gateway.login(role, email, _password());
    final own = await gateway.deniedDraft(
      session.ownCompany,
      jwt: session.jwt,
    );
    final foreign = await gateway.deniedDraft(
      session.foreignCompany,
      jwt: session.jwt,
    );
    final expectedOwn = expectedIssue317R44DraftSqlstate(
      role: role,
      foreign: false,
    );
    final expectedForeign = expectedIssue317R44DraftSqlstate(
      role: role,
      foreign: true,
    );
    final ownPass = !own.successful && own.code == expectedOwn;
    final foreignPass = !foreign.successful &&
        foreign.code == expectedForeign;
    stdout.writeln(ownPass ? 'PASS  $role own company' : 'FAIL  $role own company');
    stdout.writeln(
      foreignPass ? 'PASS  $role foreign company' : 'FAIL  $role foreign company',
    );
    if (!ownPass || !foreignPass) exitCode = 1;
  } on FormatException catch (error) {
    if (mode.single == '--preflight') {
      stderr.writeln('BLOCKED preflight — ${error.message}. No network request sent.');
    } else {
      stderr.writeln('BLOCKED — Invalid Development configuration. Details suppressed.');
    }
    exitCode = 1;
  } catch (_) {
    stderr.writeln(
      'BLOCKED — Development configuration, signed role or RPC verification failed. '
      'Sensitive data suppressed.',
    );
    exitCode = 1;
  } finally {
    gateway?.close();
  }
}
