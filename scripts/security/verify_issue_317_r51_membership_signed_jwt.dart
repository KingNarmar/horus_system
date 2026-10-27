// Issue #317 R5.1 — signed-JWT Development-only membership security probe.
//
// Usage:
// dart run scripts/security/verify_issue_317_r51_membership_signed_jwt.dart --preflight
// dart run scripts/security/verify_issue_317_r51_membership_signed_jwt.dart --execute
//
// Requires SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and the existing
// HORUS_317_COMPANY_A_ID/B_ID (or HORUS_327_COMPANY_A_ID/B_ID).
// Signs in Viewer and Owner on the same Development tenant interactively.
// Never prints passwords, tokens, emails, user IDs or raw backend errors.
// RPC requests use only a verified NONEXISTENT target membership UUID.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'issue_317_finance_join_protocol.dart';
import 'issue_317_r44_dev_test_client.dart';
import 'issue_317_r51_membership_security_contract.dart';

const _timeout = r44NetworkTimeout;
const _allowedRpcPaths = {
  '/rest/v1/rpc/change_company_member_role',
  '/rest/v1/rpc/deactivate_company_member',
  '/rest/v1/rpc/reactivate_company_member',
};

final class _Session {
  final String userId;
  final String jwt;
  final String companyId;

  const _Session(this.userId, this.jwt, this.companyId);
}

final class _Client {
  final R44DevConfig config;
  final HttpClient _client = HttpClient()..connectionTimeout = _timeout;

  _Client(this.config);

  Future<R44Reply> request(
    String method,
    String path, {
    String? jwt,
    Map<String, String>? query,
    Map<String, Object?>? data,
  }) async {
    final allowed = (method == 'POST' &&
            (path == '/auth/v1/token' || _allowedRpcPaths.contains(path))) ||
        (method == 'GET' && path == '/rest/v1/company_users');
    if (!allowed) {
      throw StateError('Unapproved R5.1 Development request.');
    }

    final uri = config.origin.resolve(path).replace(queryParameters: query);
    if (uri.scheme != 'https' ||
        uri.host != r44DevHost ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty) {
      throw StateError('Development-only endpoint required.');
    }
    final request = await _client.openUrl(method, uri).timeout(_timeout);
    request.headers.set('apikey', config.key);
    request.headers.set('Accept', 'application/json');
    if (jwt != null) request.headers.set('Authorization', 'Bearer $jwt');
    if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    final response = await request.close().timeout(_timeout);
    final raw = await utf8.decoder.bind(response).join().timeout(_timeout);
    Object? body;
    try {
      body = raw.isEmpty ? null : jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Invalid Development response.');
    }
    return R44Reply(response.statusCode, body);
  }

  Future<_Session> signIn(String role) async {
    final email = r44Prompt('$role Development test email: ');
    if (email.isEmpty) throw StateError('Test account required.');
    final result = await request(
      'POST',
      '/auth/v1/token',
      query: {'grant_type': 'password'},
      data: {'email': email, 'password': r44Password()},
    );
    final body = result.body;
    if (!result.ok ||
        body is! Map ||
        body['access_token'] is! String ||
        body['user'] is! Map) {
      throw StateError('Signed-JWT authentication failed.');
    }
    final jwt = body['access_token'] as String;
    final userId = (body['user'] as Map)['id'];
    if (userId is! String ||
        !isR44Uuid(userId) ||
        jwt.split('.').length != 3) {
      throw StateError('Invalid authenticated identity.');
    }

    final memberships = await request(
      'GET',
      '/rest/v1/company_users',
      jwt: jwt,
      query: {
        'select': 'company_id,role,is_active',
        'user_id': 'eq.$userId',
      },
    );
    final matches = memberships.rows.where(
      (row) =>
          row['is_active'] == true &&
          row['role'] == role &&
          (row['company_id'] == config.companyA ||
              row['company_id'] == config.companyB),
    ).toList();
    if (matches.length != 1) {
      throw StateError('Active company membership / role fixture invalid.');
    }
    final companyId = matches.single['company_id'];
    if (companyId is! String) {
      throw StateError('Company fixture invalid.');
    }
    return _Session(userId, jwt, companyId);
  }

  /// Resolve the sentinel against the OWNER-visible membership list.
  /// If a real row exists under this ID, do not attempt ANY mutation RPC.
  Future<void> assertSentinelIsUnused(_Session owner) async {
    final result = await request(
      'GET',
      '/rest/v1/company_users',
      jwt: owner.jwt,
      query: {
        'select': 'id',
        'company_id': 'eq.${owner.companyId}',
        'id': 'eq.$r51NonexistentMembershipId',
      },
    );
    if (result.rows.isNotEmpty) {
      throw StateError('Nonexistent membership sentinel is occupied.');
    }
  }

  void close() => _client.close(force: true);
}

Future<RealtimeJoinVerdict> _join(
  R44DevConfig config,
  String userId, {
  String? jwt,
}) async {
  final topic = r51MembershipTopic(userId);
  WebSocket? socket;
  StreamIterator<dynamic>? messages;
  try {
    socket = await WebSocket.connect(config.websocketAddress().toString())
        .timeout(_timeout);
    messages = StreamIterator<dynamic>(socket);
    socket.add(
      jsonEncode(joinFinanceTopic(topic: topic, ref: '1', jwt: jwt)),
    );
    final deadline = DateTime.now().add(_timeout);
    while (DateTime.now().isBefore(deadline)) {
      final remaining = deadline.difference(DateTime.now());
      if (!await messages.moveNext().timeout(remaining)) break;
      final verdict = parseFinanceJoinResult(
        messages.current,
        topic: topic,
        ref: '1',
      );
      if (verdict != null) return verdict;
    }
    return RealtimeJoinVerdict.inconclusive;
  } catch (_) {
    return RealtimeJoinVerdict.inconclusive;
  } finally {
    try {
      await messages?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Teardown is not evidence of a security denial.
    }
    try {
      await socket?.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Do not reveal transport details or credentials.
    }
  }
}

final class _Verdicts {
  int passed = 0;
  int failed = 0;

  void checkJoin(
    String description,
    RealtimeJoinVerdict actual,
    RealtimeJoinVerdict expected,
  ) {
    final ok = actual == expected &&
        actual != RealtimeJoinVerdict.inconclusive;
    _check(description, ok);
  }

  void checkRpc(String description, R44Reply actual, String sqlState) {
    _check(description, r51ExpectedPermissionDenial(actual, sqlState));
  }

  void _check(String description, bool ok) {
    stdout.writeln('${ok ? 'PASS' : 'FAIL'}  $description');
    if (ok) {
      passed++;
    } else {
      failed++;
    }
  }

  void finish() {
    stdout.writeln('SUMMARY: $passed PASS / $failed FAIL / 0 SKIP');
    if (failed > 0) exitCode = 1;
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      (args.single != '--preflight' && args.single != '--execute')) {
    stderr.writeln('Usage: --preflight | --execute');
    exitCode = 64;
    return;
  }

  _Client? client;
  try {
    final config = R44DevConfig.fromEnvironment();
    if (!stdin.hasTerminal) {
      throw StateError('Interactive Development terminal required.');
    }
    if (args.single == '--preflight') {
      stdout.writeln('PASS  R5.1 Development-only configuration preflight.');
      return;
    }

    client = _Client(config);
    final viewer = await client.signIn('viewer');
    final owner = await client.signIn('owner');
    if (owner.userId == viewer.userId ||
        owner.companyId != viewer.companyId) {
      throw StateError('Distinct users in the same tenant are required.');
    }
    await client.assertSentinelIsUnused(owner);

    final results = _Verdicts();
    results.checkJoin(
      'anonymous personal membership channel refused',
      await _join(config, viewer.userId),
      RealtimeJoinVerdict.denied,
    );
    results.checkJoin(
      'viewer own personal membership channel',
      await _join(config, viewer.userId, jwt: viewer.jwt),
      RealtimeJoinVerdict.allowed,
    );
    results.checkJoin(
      'owner own personal membership channel',
      await _join(config, owner.userId, jwt: owner.jwt),
      RealtimeJoinVerdict.allowed,
    );
    results.checkJoin(
      'viewer cannot join owner membership channel',
      await _join(config, owner.userId, jwt: viewer.jwt),
      RealtimeJoinVerdict.denied,
    );
    results.checkJoin(
      'owner cannot join viewer membership channel',
      await _join(config, viewer.userId, jwt: owner.jwt),
      RealtimeJoinVerdict.denied,
    );

    // Server functions check the caller role BEFORE looking up the target.
    // Even if an authorization regression exists, the nonexistent sentinel
    // cannot identify a real membership to modify.
    results.checkRpc(
      'viewer cannot change company member role',
      await client.request(
        'POST',
        '/rest/v1/rpc/change_company_member_role',
        jwt: viewer.jwt,
        data: r51DeniedRoleChangeProbe(viewer.companyId),
      ),
      'P2823',
    );
    for (final action in ['deactivate', 'reactivate']) {
      results.checkRpc(
        'viewer cannot $action company membership',
        await client.request(
          'POST',
          '/rest/v1/rpc/${action}_company_member',
          jwt: viewer.jwt,
          data: r51DeniedStatusProbe(viewer.companyId),
        ),
        'P2826',
      );
    }
    results.finish();
  } catch (_) {
    stderr.writeln(
      'BLOCKED — R5.1 Development fixtures, membership or transport invalid. '
      'Secrets suppressed. No existing membership was targeted.',
    );
    exitCode = 1;
  } finally {
    client?.close();
  }
}
