// Development-only, interactive Issue #317 security smoke.
// Uses real password-authenticated JWTs and WebSocket joins. Never writes
// business records or broadcasts messages. Never logs emails, JWTs or secrets.
// Required: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, and two fixture company IDs
// (HORUS_317_COMPANY_A_ID/B_ID or existing HORUS_327_COMPANY_A_ID/B_ID).
// Run: dart run scripts/security/verify_issue_317_signed_jwt_realtime.dart
// Or: dart run scripts/security/verify_issue_317_signed_jwt_realtime.dart --role=owner

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'issue_317_finance_join_protocol.dart';

const _roles = ['owner', 'admin', 'accountant', 'operations', 'viewer', 'driver'];
const _resources = [
  'expense_ledger',
  'trip_expenses',
  'company_expenses',
  'driver_finance',
  'driver_settlements',
  'invoices',
  'payments',
];
const _allowedRoles = {'owner', 'admin', 'accountant'};
const _timeout = Duration(seconds: 15);

final class _Config {
  final Uri url;
  final String key;
  final String companyA;
  final String companyB;
  const _Config(this.url, this.key, this.companyA, this.companyB);

  static _Config fromEnvironment() {
    String required(String variable, [String? fallback]) {
      final value = Platform.environment[variable]?.trim();
      final alternate = fallback == null
          ? null
          : Platform.environment[fallback]?.trim();
      if (value != null && value.isNotEmpty) return value;
      if (alternate != null && alternate.isNotEmpty) return alternate;
      throw StateError('Missing $variable');
    }

    final url = Uri.parse(required('SUPABASE_URL'));
    if (url.scheme != 'https' ||
        url.host != 'zwnfmszssxtfxkaofnhq.supabase.co' ||
        (url.path.isNotEmpty && url.path != '/') ||
        url.hasQuery ||
        url.hasFragment ||
        url.userInfo.isNotEmpty) {
      throw StateError('Development endpoint required.');
    }
    final key = required('SUPABASE_PUBLISHABLE_KEY');
    if (!key.startsWith('sb_publishable_')) {
      throw StateError('Client publishable key required.');
    }
    final a = required('HORUS_317_COMPANY_A_ID', 'HORUS_327_COMPANY_A_ID');
    final b = required('HORUS_317_COMPANY_B_ID', 'HORUS_327_COMPANY_B_ID');
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuid.hasMatch(a) ||
        !uuid.hasMatch(b) ||
        a.toLowerCase() == b.toLowerCase()) {
      throw StateError('Two distinct Development company IDs are required.');
    }
    if (!stdin.hasTerminal) {
      throw StateError('Interactive terminal is required, not CI.');
    }
    return _Config(url, key, a, b);
  }
}

final class _Session {
  final String token;
  final String ownCompany;
  final String foreignCompany;
  const _Session(this.token, this.ownCompany, this.foreignCompany);
}

final class _AuthReader {
  final _Config config;
  final HttpClient _client = HttpClient();
  _AuthReader(this.config);

  Future<dynamic> request(
    String method,
    String path, {
    String? token,
    Map<String, String>? query,
    Map<String, Object?>? data,
  }) async {
    final uri = config.url.resolve(path).replace(queryParameters: query);
    final request = await _client.openUrl(method, uri).timeout(_timeout);
    request.headers.set('apikey', config.key);
    if (token != null) request.headers.set('Authorization', 'Bearer $token');
    if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    final reply = await request.close().timeout(_timeout);
    if (reply.statusCode < 200 || reply.statusCode >= 300) return null;
    final text = await utf8.decoder.bind(reply).join();
    return jsonDecode(text);
  }

  Future<_Session?> signIn(
    String role,
    String email,
    String password,
  ) async {
    final result = await request(
      'POST',
      '/auth/v1/token',
      query: {'grant_type': 'password'},
      data: {'email': email, 'password': password},
    );
    if (result is! Map) return null;
    final token = result['access_token'];
    final user = result['user'];
    if (token is! String ||
        token.split('.').length != 3 ||
        user is! Map ||
        user['id'] is! String) {
      return null;
    }

    final rows = await request(
      'GET',
      '/rest/v1/company_users',
      token: token,
      query: {
        'select': 'company_id,role,is_active',
        'user_id': 'eq.${user['id']}',
      },
    );
    if (rows is! List) return null;
    final active = rows.whereType<Map>().where(
      (row) => row['is_active'] == true,
    ).toList();
    final matches = active.where(
      (row) =>
          row['role'] == role &&
          (row['company_id'] == config.companyA ||
              row['company_id'] == config.companyB),
    ).toList();
    if (matches.length != 1) return null;
    final own = matches.single['company_id'] as String;
    final foreign = own == config.companyA
        ? config.companyB
        : config.companyA;
    if (active.any((row) => row['company_id'] == foreign)) return null;
    return _Session(token, own, foreign);
  }

  void close() => _client.close(force: true);
}

String _readSecret() {
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

Future<RealtimeJoinVerdict> _join(
  _Config config,
  String companyId,
  String resource, {
  String? token,
}) async {
  final address = config.url.replace(
    scheme: 'wss',
    path: '/realtime/v1/websocket',
    queryParameters: {'apikey': config.key, 'vsn': '1.0.0'},
  );
  WebSocket? socket;
  StreamIterator<dynamic>? iterator;
  try {
    socket = await WebSocket.connect(address.toString()).timeout(_timeout);
    iterator = StreamIterator<dynamic>(socket);
    final topic = financeTopic(companyId, resource);
    socket.add(
      jsonEncode(joinFinanceTopic(topic: topic, ref: '1', jwt: token)),
    );
    final deadline = DateTime.now().add(_timeout);
    while (DateTime.now().isBefore(deadline)) {
      final pending = deadline.difference(DateTime.now());
      if (!await iterator.moveNext().timeout(pending)) break;
      final result = parseFinanceJoinResult(
        iterator.current,
        topic: topic,
        ref: '1',
      );
      if (result != null) return result;
    }
    return RealtimeJoinVerdict.inconclusive;
  } catch (_) {
    return RealtimeJoinVerdict.inconclusive;
  } finally {
    try {
      await iterator?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Never include server error details or credentials in output.
    }
    try {
      await socket?.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Treat unexpected transport failures as inconclusive, not denial.
    }
  }
}

final class _Results {
  int pass = 0;
  int fail = 0;
  int skip = 0;

  void check(String description, RealtimeJoinVerdict actual,
      RealtimeJoinVerdict expected) {
    if (actual == expected && actual != RealtimeJoinVerdict.inconclusive) {
      pass++;
      stdout.writeln('PASS  $description');
    } else {
      fail++;
      stdout.writeln(
        'FAIL  $description${actual == RealtimeJoinVerdict.inconclusive ? ' (inconclusive)' : ''}',
      );
    }
  }

  void fixtureFailed(String role) {
    fail++;
    stdout.writeln('FAIL  $role signed JWT / role membership fixture');
  }

  void missing(String role) {
    skip++;
    stdout.writeln('SKIP  $role test account missing');
  }

  void finish() {
    stdout.writeln('SUMMARY: $pass PASS / $fail FAIL / $skip SKIP');
    if (fail > 0 || skip > 0) exitCode = 1;
  }
}

Future<void> main(List<String> args) async {
  final roleArgs = args.where((arg) => arg.startsWith('--role=')).toList();
  final resourceArgs =
      args.where((arg) => arg.startsWith('--resource=')).toList();
  final roleOption = roleArgs.isEmpty
      ? null
      : roleArgs.first.substring('--role='.length);
  final resourceOption = resourceArgs.isEmpty
      ? null
      : resourceArgs.first.substring('--resource='.length);
  if (roleArgs.length > 1 ||
      resourceArgs.length > 1 ||
      args.length != roleArgs.length + resourceArgs.length ||
      (roleOption != null && !_roles.contains(roleOption)) ||
      (resourceOption != null && !_resources.contains(resourceOption))) {
    stderr.writeln(
      'Usage: ...realtime.dart [--role=owner|admin|accountant|operations|viewer|driver] '
      '[--resource=expense_ledger|trip_expenses|company_expenses|'
      'driver_finance|driver_settlements|invoices|payments]',
    );
    exitCode = 64;
    return;
  }

  late final _Config config;
  try {
    config = _Config.fromEnvironment();
  } catch (_) {
    stderr.writeln(
      'Development env missing/invalid: SUPABASE_URL, '
      'SUPABASE_PUBLISHABLE_KEY, HORUS_317_COMPANY_A_ID/B_ID '
      '(or HORUS_327_COMPANY_A_ID/B_ID).',
    );
    exitCode = 64;
    return;
  }

  final results = _Results();
  final auth = _AuthReader(config);
  try {
    for (final resource in resourceOption == null
        ? _resources
        : [resourceOption]) {
      results.check(
        'anonymous $resource refused',
        await _join(config, config.companyA, resource),
        RealtimeJoinVerdict.denied,
      );
    }
    for (final role in _roles) {
      if (roleOption != null && role != roleOption) continue;
      stdout.write('$role test email (blank to skip): ');
      final email = stdin.readLineSync()?.trim() ?? '';
      if (email.isEmpty) {
        results.missing(role);
        continue;
      }
      final password = _readSecret();
      _Session? session;
      try {
        session = await auth.signIn(role, email, password);
      } catch (_) {
        // Any auth/fixture problem is a failure, never an authorization PASS.
      }
      if (session == null) {
        results.fixtureFailed(role);
        continue;
      }
      final expected = _allowedRoles.contains(role)
          ? RealtimeJoinVerdict.allowed
          : RealtimeJoinVerdict.denied;
      for (final resource in resourceOption == null
          ? _resources
          : [resourceOption]) {
        results.check(
          '$role own $resource',
          await _join(config, session.ownCompany, resource,
              token: session.token),
          expected,
        );
        results.check(
          '$role foreign $resource refused',
          await _join(config, session.foreignCompany, resource,
              token: session.token),
          RealtimeJoinVerdict.denied,
        );
      }
    }
  } finally {
    auth.close();
  }
  results.finish();
}
