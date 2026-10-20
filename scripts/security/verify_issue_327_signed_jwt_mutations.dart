// Issue #327 — bounded Development-only signed-JWT write verification.
// Never called from Flutter, CI or the read-only --preflight runner.
// A separate operator approval is required BEFORE using --execute.
//
// Example (DO NOT RUN without that approval):
// dart run scripts/security/verify_issue_327_signed_jwt_mutations.dart \
//   --execute --case=staleTrip --role=owner --rate=26.00
//
// Required: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, HORUS_327_COMPANY_A_ID,
// HORUS_327_COMPANY_B_ID, HORUS_327_MUTATION_COMPANY_ID,
// HORUS_327_MUTATION_TRIP_ID, HORUS_327_MUTATION_ROUTE_ID,
// HORUS_327_MUTATION_INVOICED_TRIP_ID, HORUS_327_MUTATION_FIXTURE_MARKER.
// The runner never displays tokens, passwords, financial amounts or responses.

import 'dart:convert';
import 'dart:io';

import 'issue_327_mutation_checks.dart';
import 'issue_327_mutation_runner.dart';

final class _Credentials {
  final String id;
  final String jwt;

  const _Credentials(this.id, this.jwt);
}

abstract final class _Configuration {
  static String required(String name) {
    final value = Platform.environment[name]?.trim() ?? '';
    if (value.isEmpty) throw StateError('Missing configuration.');
    return value;
  }

  static MutationFixtureIds fixtures() {
    final companyA = required('HORUS_327_COMPANY_A_ID');
    final companyB = required('HORUS_327_COMPANY_B_ID');
    final company = required('HORUS_327_MUTATION_COMPANY_ID');
    if (!MutationFixtureContract.validUuid(companyA) ||
        !MutationFixtureContract.validUuid(companyB) ||
        companyA == companyB ||
        (company != companyA && company != companyB)) {
      throw StateError('Invalid Development tenants.');
    }
    final fixture = MutationFixtureIds(
      companyId: company,
      foreignCompanyId: company == companyA ? companyB : companyA,
      tripId: required('HORUS_327_MUTATION_TRIP_ID'),
      routeId: required('HORUS_327_MUTATION_ROUTE_ID'),
      invoicedTripId: required('HORUS_327_MUTATION_INVOICED_TRIP_ID'),
      marker: required('HORUS_327_MUTATION_FIXTURE_MARKER'),
    );
    if (!fixture.valid) throw StateError('Invalid isolated fixture.');
    return fixture;
  }

  static MutationRunSpec spec(List<String> args) {
    if (args.length != 4 || args.first != '--execute') {
      throw StateError('Execution requires all explicit arguments.');
    }
    final values = <String, String>{};
    for (final arg in args.skip(1)) {
      final separator = arg.indexOf('=');
      if (!arg.startsWith('--') || separator < 3) {
        throw StateError('Invalid execution argument.');
      }
      final key = arg.substring(2, separator);
      if (!{'case', 'role', 'rate'}.contains(key) ||
          values.containsKey(key)) {
        throw StateError('Unknown or repeated execution argument.');
      }
      values[key] = arg.substring(separator + 1);
    }
    final matched = MutationCase.values.where(
      (value) => value.name == values['case'],
    ).toList();
    if (matched.length != 1) throw StateError('Unrecognized test case.');
    final spec = MutationRunSpec(
      matched.single, values['role'] ?? '', values['rate'] ?? '',
    );
    if (!spec.valid) throw StateError('Role/case/rate combination denied.');
    return spec;
  }
}

// Only the required table GETs, four read/financial RPCs, and two
// field-restricted PATCH probes are reachable from this gateway.
final class _BoundedDevGateway implements MutationGateway {
  final Uri origin;
  final String publishableKey;
  final MutationFixtureIds fixture;
  final MutationRunSpec spec;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  _BoundedDevGateway(
    this.origin, this.publishableKey, this.fixture, this.spec,
  );

  Future<MutationRpcReply> _send(
    String method, String path, {
    String? jwt,
    Map<String, String>? query,
    Map<String, Object?>? data,
  }) async {
    final uri = origin.resolve(path).replace(queryParameters: query);
    if (!MutationPreflightGate.isDevelopmentOrigin(origin) ||
        uri.scheme != 'https' ||
        uri.host != MutationPreflightGate.developmentHost) {
      throw StateError('Development origin check failed.');
    }
    final request = await _client.openUrl(method, uri);
    request.headers.set('apikey', publishableKey);
    request.headers.set('Accept', 'application/json');
    if (jwt != null) {
      request.headers.set('Authorization', 'Bearer $jwt');
    }
    if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    if (method == 'PATCH') {
      request.headers.set('Prefer', 'return=representation');
    }
    final response = await request.close();
    final payload = await utf8.decoder.bind(response).join();
    Object? body;
    try {
      body = jsonDecode(payload);
    } on FormatException {
      body = null;
    }
    return MutationRpcReply(response.statusCode, body);
  }

  Future<_Credentials> signIn(String email, String password) async {
    final reply = await _send(
      'POST', '/auth/v1/token?grant_type=password',
      data: {'email': email, 'password': password},
    );
    final data = reply.body;
    if (!reply.ok || data is! Map ||
        data['access_token'] is! String ||
        data['user'] is! Map ||
        (data['user'] as Map)['id'] is! String) {
      throw StateError('Signed Development authentication rejected.');
    }
    return _Credentials(
      (data['user'] as Map)['id'] as String,
      data['access_token'] as String,
    );
  }

  @override
  Future<MutationRpcReply> get(
    String jwt, String table, Map<String, String> query,
  ) {
    if (!{
      'company_users', 'routes', 'trips', 'audit_logs', 'invoices',
    }.contains(table) || jwt.isEmpty) {
      throw StateError('Read not explicitly allowed.');
    }
    return _send('GET', '/rest/v1/$table', jwt: jwt, query: query);
  }

  @override
  Future<MutationRpcReply> rpc(
    String jwt, String function, Map<String, Object?> arguments,
  ) {
    if (jwt.isEmpty) throw StateError('Missing signed JWT.');
    if (function == 'get_authorized_trip_records') {
      if (arguments['p_company_id'] != fixture.companyId ||
          !{fixture.tripId, fixture.invoicedTripId}.contains(
            arguments['p_trip_id'],
          )) {
        throw StateError('Trip projection outside fixture.');
      }
    } else if (function == 'get_authorized_route_records') {
      if (arguments['p_company_id'] != fixture.companyId ||
          arguments['p_route_id'] != fixture.routeId ||
          arguments['p_active_only'] != false) {
        throw StateError('Route projection outside fixture.');
      }
    } else if (function == 'set_trip_freight_rate_atomic') {
      if (!spec.isTrip ||
          !{fixture.companyId, fixture.foreignCompanyId}.contains(
            arguments['p_company_id'],
          ) ||
          !{fixture.tripId, fixture.invoicedTripId}.contains(
            arguments['p_trip_id'],
          ) ||
          arguments['p_agreed_freight_rate_per_ton'] != spec.rate ||
          arguments['p_expected_updated_at'] is! String) {
        throw StateError('Trip mutation outside fixture.');
      }
    } else if (function == 'set_route_default_freight_rate_atomic') {
      if (spec.isTrip ||
          !{fixture.companyId, fixture.foreignCompanyId}.contains(
            arguments['p_company_id'],
          ) ||
          arguments['p_route_id'] != fixture.routeId ||
          arguments['p_default_freight_rate'] != spec.rate ||
          arguments['p_expected_updated_at'] is! String) {
        throw StateError('Route mutation outside fixture.');
      }
    } else {
      throw StateError('RPC is not allowed.');
    }
    return _send(
      'POST', '/rest/v1/rpc/$function',
      jwt: jwt, data: arguments,
    );
  }

  @override
  Future<MutationRpcReply> restrictedFinancialPatch(
    String jwt,
    String table,
    Map<String, String> query,
    Map<String, Object?> values,
  ) {
    final field = table == 'trips'
        ? 'agreed_freight_rate_per_ton' : 'default_freight_price';
    final record = table == 'trips' ? fixture.tripId : fixture.routeId;
    if (jwt.isEmpty || !{'trips', 'routes'}.contains(table) ||
        query.length != 2 ||
        query['company_id'] != 'eq.${fixture.companyId}' ||
        query['id'] != 'eq.${record}' ||
        values.length != 1 ||
        values[field] != num.parse(spec.rate)) {
      throw StateError('Direct mutation outside financial fixture.');
    }
    return _send(
      'PATCH', '/rest/v1/$table',
      jwt: jwt, query: query, data: values,
    );
  }

  void close() => _client.close(force: true);
}

String _readLine(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync()?.trim() ?? '';
}

String _secret() {
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
  _BoundedDevGateway? gateway;
  try {
    // Validate everything BEFORE sign-in or any network request.
    final spec = _Configuration.spec(args);
    final fixture = _Configuration.fixtures();
    final origin = Uri.tryParse(_Configuration.required('SUPABASE_URL'));
    final publishableKey = _Configuration.required('SUPABASE_PUBLISHABLE_KEY');
    if (origin == null ||
        !MutationPreflightGate.isDevelopmentOrigin(origin) ||
        !publishableKey.startsWith('sb_publishable_') ||
        !stdin.hasTerminal) {
      throw StateError('Unsafe environment or non-interactive execution.');
    }

    stdout.writeln('DEVELOPMENT MUTATION TEST — explicit approval required');
    stdout.writeln('Case: ${spec.testCase.name}, role: ${spec.role}');
    final confirmation = _readLine(
      'Type EXECUTE + fixture marker + case name, separated by spaces: ',
    );
    if (confirmation !=
        'EXECUTE ${fixture.marker} ${spec.testCase.name}') {
      throw StateError('Operator confirmation missing.');
    }

    gateway = _BoundedDevGateway(
      origin, publishableKey, fixture, spec,
    );
    final observerEmail = _readLine('Fixture owner/admin email: ');
    if (observerEmail.isEmpty) throw StateError('Observer required.');
    final observer = await gateway.signIn(observerEmail, _secret());
    final _Credentials actor;
    if (spec.role == 'owner' || spec.role == 'admin') {
      actor = observer;
    } else {
      final actorEmail = _readLine('Actor ${spec.role} email: ');
      if (actorEmail.isEmpty) throw StateError('Actor required.');
      actor = await gateway.signIn(actorEmail, _secret());
    }

    final result = await Issue327MutationRunner(gateway).run(
      fixture: fixture,
      spec: spec,
      observerJwt: observer.jwt,
      observerId: observer.id,
      actorJwt: actor.jwt,
      actorId: actor.id,
    );
    stdout.writeln(
      '${result.passed ? 'PASS  ' : 'FAIL  '}${result.check}',
    );
    if (!result.passed) exitCode = 1;
  } catch (_) {
    stderr.writeln(
      'BLOCKED — test precondition or verification failed. '
      'Sensitive details suppressed.',
    );
    exitCode = 1;
  } finally {
    gateway?.close();
  }
}
