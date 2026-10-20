import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/security/issue_327_mutation_checks.dart';
import '../../../scripts/security/issue_327_mutation_runner.dart';

const _company = '00000000-0000-0000-0000-000000000001';
const _foreign = '00000000-0000-0000-0000-000000000002';
const _trip = '00000000-0000-0000-0000-000000000003';
const _route = '00000000-0000-0000-0000-000000000004';
const _billed = '00000000-0000-0000-0000-000000000005';
const _owner = '00000000-0000-0000-0000-000000000006';
const _actor = '00000000-0000-0000-0000-000000000007';
const _invoice = '00000000-0000-0000-0000-000000000008';
const _marker = 'HORUS327-ISOLATED-TEST-001';

const _fixtures = MutationFixtureIds(
  companyId: _company,
  foreignCompanyId: _foreign,
  tripId: _trip,
  routeId: _route,
  invoicedTripId: _billed,
  marker: _marker,
);

Object? _clone(Object? value) => jsonDecode(jsonEncode(value));

final class _FakeGateway implements MutationGateway {
  final String role;
  bool brokenFixture = false;
  bool maliciousResponse = false;
  int writes = 0;

  final Map<String, Object?> route = {
    'id': _route,
    'company_id': _company,
    'notes': _marker,
    'created_by': null,
    'is_active': true,
    'default_freight_price': 10,
    'updated_at': '2026-10-20T09:00:00+00:00',
  };
  final Map<String, Object?> trip = {
    'id': _trip,
    'company_id': _company,
    'route_id': _route,
    'notes': _marker,
    'created_by': _owner,
    'invoice_id': null,
    'quantity_tons': 10,
    'freight_price': 250,
    'agreed_freight_rate_per_ton': 25,
    'total_expenses': 0,
    'updated_at': '2026-10-20T09:00:00+00:00',
  };
  final Map<String, Object?> billed = {
    'id': _billed,
    'company_id': _company,
    'route_id': _route,
    'notes': _marker,
    'created_by': _owner,
    'invoice_id': _invoice,
    'quantity_tons': 5,
    'freight_price': 150,
    'agreed_freight_rate_per_ton': 30,
    'total_expenses': 0,
    'updated_at': '2026-10-20T09:00:00+00:00',
  };
  final List<Map<String, Object?>> audit = [
    {
      'id': 'create-route',
      'company_id': _company,
      'module': 'routes',
      'entity_type': 'route',
      'entity_id': _route,
      'action': 'created',
      'actor_user_id': _owner,
      'actor_role': 'owner',
      'old_values': null,
      'new_values': {'id': _route, 'company_id': _company, 'notes': _marker},
      'metadata': {'audit_event': 'route_created'},
      'created_at': '2026-10-20T08:00:00+00:00',
    },
  ];

  _FakeGateway(this.role);

  @override
  Future<MutationRpcReply> get(
    String jwt,
    String table,
    Map<String, String> query,
  ) async {
    final List<Object?> rows;
    switch (table) {
      case 'company_users':
        rows = [
          {
            'user_id': _owner,
            'role': 'owner',
            'company_id': _company,
            'is_active': true,
          },
          if (role != 'owner')
            {
              'user_id': _actor,
              'role': role,
              'company_id': _company,
              'is_active': true,
            },
        ].where((r) => r['user_id'] == query['user_id']?.substring(3)).toList();
      case 'routes':
        rows = [route];
      case 'trips':
        rows = [if (query['id'] == 'eq.$_trip') trip else billed];
      case 'invoices':
        rows = [
          {'id': _invoice, 'company_id': _company, 'status': 'issued'},
        ];
      case 'audit_logs':
        rows = audit
            .where(
              (r) =>
                  r['entity_id'] == query['entity_id']?.substring(3) &&
                  (query['action'] == null ||
                      r['action'] == query['action']?.substring(3)),
            )
            .toList();
      default:
        throw StateError('Fake received unsupported table.');
    }
    if (brokenFixture && table == 'routes') {
      return MutationRpcReply(200, [
        {...route, 'notes': 'real-customer-route'},
      ]);
    }
    return MutationRpcReply(200, _clone(rows));
  }

  @override
  Future<MutationRpcReply> rpc(
    String jwt,
    String function,
    Map<String, Object?> arguments,
  ) async {
    if (function == 'get_authorized_trip_records') {
      return MutationRpcReply(200, [
        _clone(arguments['p_trip_id'] == _trip ? trip : billed),
      ]);
    }
    if (function == 'get_authorized_route_records') {
      return MutationRpcReply(200, [_clone(route)]);
    }
    writes++;
    final isTrip = function == 'set_trip_freight_rate_atomic';
    final target = isTrip ? trip : route;
    final requested = num.parse(
      (arguments[isTrip
              ? 'p_agreed_freight_rate_per_ton'
              : 'p_default_freight_rate']
          as String),
    );

    if (arguments['p_company_id'] == _foreign ||
        role == 'operations' ||
        role == 'viewer' ||
        role == 'driver') {
      return const MutationRpcReply(403, {'code': 'P3431'});
    }
    if (arguments['p_trip_id'] == _billed) {
      return const MutationRpcReply(409, {'code': 'P3436'});
    }
    if (arguments['p_expected_updated_at'] != target['updated_at']) {
      return MutationRpcReply(409, {'code': isTrip ? 'P3414' : 'P3440'});
    }
    final old = Map<String, Object?>.from(target);
    target[isTrip ? 'agreed_freight_rate_per_ton' : 'default_freight_price'] =
        requested;
    if (isTrip) target['freight_price'] = requested * 10;
    target['updated_at'] = '2026-10-20T09:01:00+00:00';
    audit.add({
      'id': 'new-audit',
      'company_id': _company,
      'module': isTrip ? 'trips' : 'routes',
      'entity_type': isTrip ? 'trip' : 'route',
      'entity_id': isTrip ? _trip : _route,
      'action': 'updated',
      'actor_user_id': role == 'owner' ? _owner : _actor,
      'old_values': old,
      'new_values': Map<String, Object?>.from(target),
      'metadata': {'financial_terms_changed': true},
    });
    return MutationRpcReply(
      200,
      _clone(maliciousResponse ? {...target, 'company_id': _foreign} : target),
    );
  }

  @override
  Future<MutationRpcReply> restrictedFinancialPatch(
    String jwt,
    String table,
    Map<String, String> query,
    Map<String, Object?> values,
  ) async {
    writes++;
    return const MutationRpcReply(403, {'code': '42501'});
  }
}

Future<MutationRunResult> _run(
  _FakeGateway gateway,
  MutationCase testCase,
  String role, {
  String rate = '26.00',
}) => Issue327MutationRunner(gateway).run(
  fixture: _fixtures,
  spec: MutationRunSpec(testCase, role, rate),
  observerJwt: 'owner-jwt',
  observerId: _owner,
  actorJwt: role == 'owner' ? 'owner-jwt' : 'actor-jwt',
  actorId: role == 'owner' ? _owner : _actor,
);

void main() {
  test('roles and amounts are fixed to explicit case matrix', () {
    expect(
      const MutationRunSpec(MutationCase.tripRate, 'accountant', '26.00').valid,
      isTrue,
    );
    expect(
      const MutationRunSpec(MutationCase.deniedTrip, 'owner', '26.00').valid,
      isFalse,
    );
    expect(
      const MutationRunSpec(MutationCase.tripRate, 'operations', '26.00').valid,
      isFalse,
    );
    expect(
      const MutationRunSpec(MutationCase.tripRate, 'owner', '1000').valid,
      isFalse,
    );
    expect(
      const MutationRunSpec(MutationCase.tripRate, 'owner', '-1').valid,
      isFalse,
    );
    expect(
      const MutationRunSpec(MutationCase.tripRate, 'owner', '1.234').valid,
      isFalse,
    );
  });

  test('unsafe fixture prevents all mutations', () async {
    final gateway = _FakeGateway('owner')..brokenFixture = true;
    await expectLater(
      _run(gateway, MutationCase.tripRate, 'owner'),
      throwsStateError,
    );
    expect(gateway.writes, 0);
  });

  test('actor role cannot be substituted for a finance role', () async {
    final gateway = _FakeGateway('viewer');
    await expectLater(
      _run(gateway, MutationCase.tripRate, 'accountant'),
      throwsStateError,
    );
    expect(gateway.writes, 0);
  });

  test('signed-JWT owner pricing checks response, state and audit', () async {
    final gateway = _FakeGateway('owner');
    final result = await _run(gateway, MutationCase.tripRate, 'owner');
    expect(result.passed, isTrue);
    expect(gateway.writes, 1);
    expect(gateway.trip['agreed_freight_rate_per_ton'], 26);
  });

  test('accountant Route pricing uses finance-only RPC', () async {
    final gateway = _FakeGateway('accountant');
    final result = await _run(
      gateway,
      MutationCase.routeRate,
      'accountant',
      rate: '11.00',
    );
    expect(result.passed, isTrue);
    expect(gateway.writes, 1);
    expect(gateway.route['default_freight_price'], 11);
  });

  test('Route pricing allows an unset current rate', () async {
    final gateway = _FakeGateway('owner');
    gateway.route['default_freight_price'] = null;
    final result = await _run(
      gateway,
      MutationCase.routeRate,
      'owner',
      rate: '11.00',
    );
    expect(result.passed, isTrue);
    expect(gateway.writes, 1);
    expect(gateway.route['default_freight_price'], 11);
    expect(gateway.audit.length, 2);
  });

  test('Route pricing rejects a malformed current rate before writing', () async {
    final gateway = _FakeGateway('owner');
    gateway.route['default_freight_price'] = 'invalid';
    await expectLater(
      _run(gateway, MutationCase.routeRate, 'owner', rate: '11.00'),
      throwsStateError,
    );
    expect(gateway.writes, 0);
  });

  test('Route pricing refuses a no-op with no mutation', () async {
    final gateway = _FakeGateway('owner');
    await expectLater(
      _run(gateway, MutationCase.routeRate, 'owner', rate: '10.00'),
      throwsStateError,
    );
    expect(gateway.writes, 0);
  });

  test('invoiced lock does not touch trip, invoice or audit', () async {
    final gateway = _FakeGateway('owner');
    final result = await _run(
      gateway,
      MutationCase.invoicedTrip,
      'owner',
      rate: '31.00',
    );
    expect(result.passed, isTrue);
    expect(gateway.writes, 1);
    expect(gateway.billed['agreed_freight_rate_per_ton'], 30);
  });

  test('stale Trip and Route fail without audit writes', () async {
    for (final testCase in [MutationCase.staleTrip, MutationCase.staleRoute]) {
      final gateway = _FakeGateway('owner');
      final result = await _run(gateway, testCase, 'owner', rate: '11.00');
      expect(result.passed, isTrue);
      expect(gateway.writes, 1);
      expect(gateway.audit.length, 1);
    }
  });

  test('unauthorized RPC and direct PATCH never alter money', () async {
    for (final testCase in [
      MutationCase.deniedTrip,
      MutationCase.deniedRoute,
      MutationCase.directTrip,
      MutationCase.directRoute,
    ]) {
      final gateway = _FakeGateway('operations');
      final result = await _run(gateway, testCase, 'operations', rate: '11.00');
      expect(result.passed, isTrue);
      expect(gateway.writes, 1);
      expect(gateway.audit.length, 1);
    }
  });

  test('foreign-tenant company argument is rejected before changes', () async {
    for (final testCase in [
      MutationCase.foreignTrip,
      MutationCase.foreignRoute,
    ]) {
      final gateway = _FakeGateway('owner');
      final result = await _run(gateway, testCase, 'owner', rate: '11.00');
      expect(result.passed, isTrue);
      expect(gateway.audit.length, 1);
    }
  });

  test('forged success response fails even when server changed data', () async {
    final gateway = _FakeGateway('owner')..maliciousResponse = true;
    final result = await _run(gateway, MutationCase.tripRate, 'owner');
    expect(result.passed, isFalse);
  });
}
