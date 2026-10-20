// Issue #327 — signed-JWT Development fixture preflight (READ ONLY).
//
// Usage: dart run scripts/security/verify_issue_327_mutations.dart --preflight
//
// Required environment (in addition to the existing JWT-read harness):
// SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, HORUS_327_COMPANY_A_ID,
// HORUS_327_COMPANY_B_ID, HORUS_327_MUTATION_COMPANY_ID,
// HORUS_327_MUTATION_TRIP_ID, HORUS_327_MUTATION_ROUTE_ID,
// HORUS_327_MUTATION_INVOICED_TRIP_ID, HORUS_327_MUTATION_FIXTURE_MARKER.
//
// No mutation operation is implemented. --execute is always rejected.
// This only validates explicitly marked, dedicated test fixtures and their
// ownership; it never selects an arbitrary real-world Trip or Route.

import 'dart:convert';
import 'dart:io';

import 'issue_327_mutation_checks.dart';

abstract final class _Config {
  static const required = [
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'HORUS_327_COMPANY_A_ID',
    'HORUS_327_COMPANY_B_ID',
    'HORUS_327_MUTATION_COMPANY_ID',
    'HORUS_327_MUTATION_TRIP_ID',
    'HORUS_327_MUTATION_ROUTE_ID',
    'HORUS_327_MUTATION_INVOICED_TRIP_ID',
    'HORUS_327_MUTATION_FIXTURE_MARKER',
  ];

  static String read(String key) {
    final value = Platform.environment[key]?.trim() ?? '';
    if (value.isEmpty) throw StateError('Missing environment: $key');
    return value;
  }

  static Uri developmentUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || !MutationPreflightGate.isDevelopmentOrigin(uri)) {
      throw StateError('Only H.O.R.U.S Development is permitted.');
    }
    return uri;
  }

  static MutationFixtureIds fixtureIds() {
    final companyA = read('HORUS_327_COMPANY_A_ID');
    final companyB = read('HORUS_327_COMPANY_B_ID');
    final companyId = read('HORUS_327_MUTATION_COMPANY_ID');
    if (!MutationFixtureContract.validUuid(companyA) ||
        !MutationFixtureContract.validUuid(companyB) ||
        companyA == companyB ||
        (companyId != companyA && companyId != companyB)) {
      throw StateError('Fixture company must be one of two distinct tenants.');
    }
    final ids = MutationFixtureIds(
      companyId: companyId,
      foreignCompanyId: companyId == companyA ? companyB : companyA,
      tripId: read('HORUS_327_MUTATION_TRIP_ID'),
      routeId: read('HORUS_327_MUTATION_ROUTE_ID'),
      invoicedTripId: read('HORUS_327_MUTATION_INVOICED_TRIP_ID'),
      marker: read('HORUS_327_MUTATION_FIXTURE_MARKER'),
    );
    if (!ids.valid) {
      throw StateError('Fixture IDs or isolation marker are invalid.');
    }
    return ids;
  }
}

final class _HttpReply {
  final int status;
  final Object? body;

  const _HttpReply(this.status, this.body);

  bool get ok => status >= 200 && status < 300;
}

// Intentionally exposes only login and table GET. There is no RPC or write API.
final class _ReadOnlyDevClient {
  final Uri origin;
  final String publishableKey;
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  _ReadOnlyDevClient(this.origin, this.publishableKey);

  Future<_HttpReply> login(String email, String password) async {
    final uri = origin.resolve('/auth/v1/token?grant_type=password');
    final request = await _http.postUrl(uri);
    request.headers.set('apikey', publishableKey);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'email': email, 'password': password}));
    return _finish(request);
  }

  Future<_HttpReply> read(
    String table,
    Map<String, String> params,
    String jwt,
  ) async {
    if (!{'company_users', 'trips', 'routes', 'audit_logs'}.contains(table)) {
      throw StateError('Table is not allowed in read-only preflight.');
    }
    final uri = origin.resolve('/rest/v1/$table').replace(
      queryParameters: params,
    );
    final request = await _http.getUrl(uri);
    request.headers.set('apikey', publishableKey);
    request.headers.set('Authorization', 'Bearer $jwt');
    request.headers.set('Accept', 'application/json');
    return _finish(request);
  }

  Future<_HttpReply> _finish(HttpClientRequest request) async {
    final response = await request.close();
    final content = await utf8.decoder.bind(response).join();
    Object? body;
    try {
      body = jsonDecode(content);
    } on FormatException {
      body = null;
    }
    return _HttpReply(response.statusCode, body);
  }

  void close() => _http.close(force: true);
}

String _readPassword() {
  stdout.write('Password (hidden): ');
  final previousEcho = stdin.echoMode;
  try {
    stdin.echoMode = false;
    return stdin.readLineSync() ?? '';
  } finally {
    stdin.echoMode = previousEcho;
    stdout.writeln();
  }
}

bool _reportCheck(String label, bool condition) {
  stdout.writeln('${condition ? 'PASS' : 'BLOCKED'}  $label');
  return condition;
}

Future<void> main(List<String> args) async {
  // Explicit deny-by-default. Even --execute never creates or changes data.
  if (!MutationPreflightGate.allowsArguments(args)) {
    stderr.writeln(
      'Only --preflight is supported. Mutation execution is NOT enabled.',
    );
    exitCode = 64;
    return;
  }

  try {
    // Validate target, key and fixture intent BEFORE any network access.
    for (final key in _Config.required) {
      _Config.read(key);
    }
    final origin = _Config.developmentUrl(_Config.read('SUPABASE_URL'));
    final key = _Config.read('SUPABASE_PUBLISHABLE_KEY');
    if (key.startsWith('sb_secret_')) {
      throw StateError('Secret keys are not accepted.');
    }
    final ids = _Config.fixtureIds();
    if (!stdin.hasTerminal) {
      throw StateError('Interactive terminal required. Not for CI.');
    }

    stdout.writeln('READ-ONLY DEVELOPMENT PREFLIGHT — no mutations available');
    stdout.write('Fixture owner/admin email (blank to cancel): ');
    final email = stdin.readLineSync()?.trim() ?? '';
    if (email.isEmpty) {
      stdout.writeln('BLOCKED  preflight cancelled');
      exitCode = 1;
      return;
    }
    final password = _readPassword();
    final client = _ReadOnlyDevClient(origin, key);
    try {
      final login = await client.login(email, password);
      final auth = login.body;
      if (!login.ok || auth is! Map ||
          auth['access_token'] is! String ||
          auth['user'] is! Map ||
          (auth['user'] as Map)['id'] is! String) {
        throw StateError('Signed-JWT login failed.');
      }
      final userId = (auth['user'] as Map)['id'] as String;
      final jwt = auth['access_token'] as String;

      final members = await client.read('company_users', {
        'select': 'user_id,role,company_id,is_active',
        'user_id': 'eq.$userId',
      }, jwt);
      if (!_reportCheck(
        'active owner/admin and single-tenant membership',
        members.ok && MutationPreflightChecks.activeAuthorizedMember(
          members.body, userId, ids.companyId, ids.foreignCompanyId,
        ),
      )) {
        exitCode = 1;
        return;
      }

      final route = await client.read('routes', {
        'select': 'id,company_id,notes,created_by,is_active,updated_at',
        'company_id': 'eq.${ids.companyId}',
        'id': 'eq.${ids.routeId}',
      }, jwt);
      final tripColumns = 'id,company_id,route_id,notes,created_by,'
          'invoice_id,quantity_tons,updated_at';
      final trip = await client.read('trips', {
        'select': tripColumns,
        'company_id': 'eq.${ids.companyId}',
        'id': 'eq.${ids.tripId}',
      }, jwt);
      final invoicedTrip = await client.read('trips', {
        'select': tripColumns,
        'company_id': 'eq.${ids.companyId}',
        'id': 'eq.${ids.invoicedTripId}',
      }, jwt);

      final routeOk = _reportCheck(
        'isolated tagged Route belongs to signed-in creator',
        route.ok &&
            MutationPreflightChecks.isolatedRoute(
              route.body, ids, userId,
            ),
      );
      final tripOk = _reportCheck(
        'isolated unbilled Trip belongs to Route and signed-in creator',
        trip.ok &&
            MutationPreflightChecks.isolatedTrip(
              trip.body, ids, userId,
            ),
      );
      final billedOk = _reportCheck(
        'isolated billed Trip for invoiced lock test',
        invoicedTrip.ok &&
            MutationPreflightChecks.isolatedInvoicedTrip(
              invoicedTrip.body, ids, userId,
            ),
      );

      final audits = await client.read('audit_logs', {
        'select': 'id,company_id,entity_id,action',
        'company_id': 'eq.${ids.companyId}',
        'entity_id': 'eq.${ids.tripId}',
        'limit': '2',
      }, jwt);
      final auditOk = _reportCheck(
        'read access to company-scoped audit baseline',
        audits.ok &&
            audits.body is List &&
            (audits.body as List).every(
              (row) => row is Map &&
                  row['company_id'] == ids.companyId &&
                  row['entity_id'] == ids.tripId,
            ),
      );

      if (routeOk && tripOk && billedOk && auditOk) {
        stdout.writeln(
          'PREFLIGHT READY — request separate approval before mutation tests.',
        );
      } else {
        stdout.writeln(
          'PREFLIGHT BLOCKED — do not write or reuse ordinary business rows.',
        );
        exitCode = 1;
      }
    } finally {
      client.close();
    }
  } catch (_) {
    stderr.writeln(
      'PREFLIGHT BLOCKED — configuration, credentials or read check failed.'
      ' Sensitive details suppressed.',
    );
    exitCode = 1;
  }
}
