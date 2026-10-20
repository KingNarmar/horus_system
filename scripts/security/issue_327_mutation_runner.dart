// Issue #327: bounded signed-JWT mutation verification engine.
// This file has no I/O and never creates a network client. All writes require
// an injected gateway and an explicitly validated, isolated Development fixture.

import 'issue_327_mutation_checks.dart';

enum MutationCase {
  tripRate,
  routeRate,
  invoicedTrip,
  staleTrip,
  staleRoute,
  deniedTrip,
  deniedRoute,
  directTrip,
  directRoute,
  foreignTrip,
  foreignRoute,
}

final class MutationRunSpec {
  final MutationCase testCase;
  final String role;
  final String rate;

  const MutationRunSpec(this.testCase, this.role, this.rate);

  bool get valid {
    final finance = {'owner', 'admin', 'accountant'};
    final nonFinance = {'operations', 'viewer', 'driver'};
    final roles = switch (testCase) {
      MutationCase.deniedTrip ||
      MutationCase.deniedRoute ||
      MutationCase.directTrip ||
      MutationCase.directRoute => nonFinance,
      _ => finance,
    };
    if (!roles.contains(role) ||
        !RegExp(r'^[0-9]{1,3}(\.[0-9]{1,2})?$').hasMatch(rate)) {
      return false;
    }
    final number = num.tryParse(rate);
    return number != null && number > 0;
  }

  bool get isTrip => switch (testCase) {
    MutationCase.routeRate ||
    MutationCase.staleRoute ||
    MutationCase.deniedRoute ||
    MutationCase.directRoute ||
    MutationCase.foreignRoute => false,
    _ => true,
  };

  bool get expectsSuccess =>
      testCase == MutationCase.tripRate || testCase == MutationCase.routeRate;
}

abstract interface class MutationGateway {
  Future<MutationRpcReply> get(
    String jwt,
    String table,
    Map<String, String> query,
  );

  Future<MutationRpcReply> rpc(
    String jwt,
    String function,
    Map<String, Object?> arguments,
  );

  Future<MutationRpcReply> restrictedFinancialPatch(
    String jwt,
    String table,
    Map<String, String> query,
    Map<String, Object?> values,
  );
}

final class MutationRunResult {
  final bool passed;
  final String check;

  const MutationRunResult(this.passed, this.check);
}

final class Issue327MutationRunner {
  final MutationGateway gateway;

  const Issue327MutationRunner(this.gateway);

  Future<MutationRunResult> run({
    required MutationFixtureIds fixture,
    required MutationRunSpec spec,
    required String observerJwt,
    required String observerId,
    required String actorJwt,
    required String actorId,
  }) async {
    // Abort BEFORE the first mutation if any precondition fails.
    if (!fixture.valid || !spec.valid ||
        !MutationFixtureContract.validUuid(observerId) ||
        !MutationFixtureContract.validUuid(actorId) ||
        observerJwt.isEmpty || actorJwt.isEmpty) {
      throw StateError('Invalid isolated-fixture or session precondition.');
    }

    final observerMembership = await _rows(observerJwt, 'company_users', {
      'select': 'company_id,user_id,role,is_active',
      'user_id': 'eq.$observerId',
    });
    if (!MutationPreflightChecks.activeAuthorizedMember(
      observerMembership, observerId, fixture.companyId,
      fixture.foreignCompanyId,
    )) {
      throw StateError('Fixture owner/admin precondition rejected.');
    }
    final actorMembership = await _rows(actorJwt, 'company_users', {
      'select': 'company_id,user_id,role,is_active',
      'user_id': 'eq.$actorId',
    });
    if (!_actorMembership(
      actorMembership, actorId, fixture, spec.role,
    )) {
      throw StateError('Actor role/tenant precondition rejected.');
    }

    final route = await _rows(observerJwt, 'routes', {
      'select': 'id,company_id,notes,created_by,is_active,updated_at',
      'company_id': 'eq.${fixture.companyId}',
      'id': 'eq.${fixture.routeId}',
    });
    final routeAudits = await _rows(observerJwt, 'audit_logs', {
      'select': 'company_id,module,entity_type,entity_id,action,'
          'actor_user_id,actor_role,old_values,new_values,metadata,created_at',
      'company_id': 'eq.${fixture.companyId}',
      'entity_id': 'eq.${fixture.routeId}',
      'module': 'eq.routes',
      'entity_type': 'eq.route',
      'action': 'eq.created',
      'limit': '2',
    });
    final tripColumns = 'id,company_id,route_id,notes,created_by,'
        'invoice_id,quantity_tons,updated_at';
    final trip = await _rows(observerJwt, 'trips', {
      'select': tripColumns,
      'company_id': 'eq.${fixture.companyId}',
      'id': 'eq.${fixture.tripId}',
    });
    final invoicedTrip = await _rows(observerJwt, 'trips', {
      'select': tripColumns,
      'company_id': 'eq.${fixture.companyId}',
      'id': 'eq.${fixture.invoicedTripId}',
    });
    if (!MutationPreflightChecks.isolatedRoute(
          route, fixture, observerId, creationAudits: routeAudits,
        ) ||
        !MutationPreflightChecks.isolatedTrip(
          trip, fixture, observerId,
        ) ||
        !MutationPreflightChecks.isolatedInvoicedTrip(
          invoicedTrip, fixture, observerId,
        )) {
      throw StateError('Tagged, creator-owned fixtures not verified.');
    }

    final targetId = spec.testCase == MutationCase.invoicedTrip
        ? fixture.invoicedTripId
        : (spec.isTrip ? fixture.tripId : fixture.routeId);
    final table = spec.isTrip ? 'trips' : 'routes';
    final current = await _projection(
      observerJwt, fixture.companyId, targetId, spec.isTrip,
    );
    final rateField = spec.isTrip
        ? 'agreed_freight_rate_per_ton' : 'default_freight_price';
    final currentRate = current[rateField];
    if (current['notes'] != fixture.marker ||
        current['updated_at'] is! String ||
        DateTime.tryParse(current['updated_at'] as String) == null ||
        (currentRate != null && currentRate is! num) ||
        currentRate == num.parse(spec.rate)) {
      throw StateError('Target snapshot/rate is not safe for test.');
    }

    final invoiceId = spec.testCase == MutationCase.invoicedTrip
        ? invoicedTrip.single['invoice_id'] as String
        : null;
    final invoiceBefore = invoiceId == null
        ? null
        : await _rows(observerJwt, 'invoices', {
            'select': '*',
            'company_id': 'eq.${fixture.companyId}',
            'id': 'eq.$invoiceId',
          });
    if (invoiceId != null && invoiceBefore!.length != 1) {
      throw StateError('Invoiced fixture invoice is not readable.');
    }

    final auditBefore = await _audits(observerJwt, fixture, targetId);
    final expectedTimestamp = switch (spec.testCase) {
      MutationCase.staleTrip || MutationCase.staleRoute =>
        '2000-01-01T00:00:00Z',
      _ => current['updated_at'] as String,
    };
    final company = switch (spec.testCase) {
      MutationCase.foreignTrip || MutationCase.foreignRoute =>
        fixture.foreignCompanyId,
      _ => fixture.companyId,
    };

    // The ONLY possible writes are the named financial RPCs or restricted
    // direct PATCH probes on previously verified fixture rows.
    final MutationRpcReply reply;
    if (spec.testCase == MutationCase.directTrip ||
        spec.testCase == MutationCase.directRoute) {
      reply = await gateway.restrictedFinancialPatch(
        actorJwt,
        table,
        {
          'company_id': 'eq.${fixture.companyId}',
          'id': 'eq.$targetId',
        },
        {rateField: num.parse(spec.rate)},
      );
    } else {
      reply = await gateway.rpc(
        actorJwt,
        spec.isTrip
            ? 'set_trip_freight_rate_atomic'
            : 'set_route_default_freight_rate_atomic',
        spec.isTrip
            ? {
                'p_company_id': company,
                'p_trip_id': targetId,
                'p_agreed_freight_rate_per_ton': spec.rate,
                'p_expected_updated_at': expectedTimestamp,
              }
            : {
                'p_company_id': company,
                'p_route_id': targetId,
                'p_default_freight_rate': spec.rate,
                'p_expected_updated_at': expectedTimestamp,
              },
      );
    }

    final after = await _projection(
      observerJwt, fixture.companyId, targetId, spec.isTrip,
    );
    final auditAfter = await _audits(observerJwt, fixture, targetId);
    if (invoiceId != null) {
      final invoiceAfter = await _rows(observerJwt, 'invoices', {
        'select': '*',
        'company_id': 'eq.${fixture.companyId}',
        'id': 'eq.$invoiceId',
      });
      if (!MutationRpcChecks.unchanged(invoiceBefore, invoiceAfter)) {
        return const MutationRunResult(false, 'invoice changed');
      }
    }

    if (spec.expectsSuccess) {
      final newAudits = auditAfter.where((audit) =>
          !auditBefore.any((old) => old['id'] == audit['id'])).toList();
      final rightAudit = newAudits.length == 1 &&
          (spec.isTrip
              ? MutationRpcChecks.financialAudit(
                  newAudits,
                  companyId: fixture.companyId,
                  tripId: targetId,
                  actorUserId: actorId,
                )
              : _routeAudit(
                  newAudits.single, fixture.companyId, targetId, actorId,
                ));
      final response = reply.body;
      final passed = reply.ok &&
          response is Map &&
          response['id'] == targetId &&
          response['company_id'] == fixture.companyId &&
          after[rateField] == num.parse(spec.rate) &&
          response[rateField] == num.parse(spec.rate) &&
          !MutationRpcChecks.unchanged(current, after) &&
          rightAudit;
      return MutationRunResult(passed, 'authorized rate and server audit');
    }

    final expectedCode = switch (spec.testCase) {
      MutationCase.invoicedTrip => 'P3436',
      MutationCase.staleTrip => 'P3414',
      MutationCase.staleRoute => 'P3440',
      MutationCase.directTrip || MutationCase.directRoute => '42501',
      _ => 'P3431',
    };
    final denied = MutationRpcChecks.denied(reply, expectedCode);
    final passed = denied &&
        MutationRpcChecks.unchanged(current, after) &&
        MutationRpcChecks.unchanged(auditBefore, auditAfter);
    return MutationRunResult(passed, 'denial, immutable snapshot and audit');
  }

  Future<List<Map>> _rows(
    String jwt,
    String table,
    Map<String, String> query,
  ) async {
    final response = await gateway.get(jwt, table, query);
    if (!response.ok || response.body is! List ||
        (response.body as List).any((row) => row is! Map)) {
      throw StateError('Required signed-JWT read failed.');
    }
    return (response.body as List).cast<Map>();
  }

  Future<Map> _projection(
    String jwt, String company, String record, bool trip,
  ) async {
    final reply = await gateway.rpc(
      jwt,
      trip ? 'get_authorized_trip_records' : 'get_authorized_route_records',
      trip
          ? {'p_company_id': company, 'p_trip_id': record}
          : {
              'p_company_id': company,
              'p_route_id': record,
              'p_active_only': false,
            },
    );
    if (!reply.ok || reply.body is! List ||
        (reply.body as List).length != 1 ||
        (reply.body as List).single is! Map) {
      throw StateError('Authoritative projection is unavailable.');
    }
    final row = (reply.body as List).single as Map;
    if (row['id'] != record || row['company_id'] != company) {
      throw StateError('Projection crossed fixture boundary.');
    }
    return row;
  }

  Future<List<Map>> _audits(
    String jwt, MutationFixtureIds ids, String recordId,
  ) => _rows(jwt, 'audit_logs', {
    'select': 'id,company_id,module,entity_type,entity_id,action,'
        'actor_user_id,old_values,new_values,metadata',
    'company_id': 'eq.${ids.companyId}',
    'entity_id': 'eq.$recordId',
    'order': 'id.asc',
    'limit': '1000',
  });

  static bool _actorMembership(
    List<Map> rows, String userId, MutationFixtureIds ids, String role,
  ) {
    final active = rows.where((r) =>
        r['user_id'] == userId && r['is_active'] == true).toList();
    return active.length == 1 &&
        active.single['company_id'] == ids.companyId &&
        active.single['role'] == role &&
        !active.any((r) => r['company_id'] == ids.foreignCompanyId);
  }

  static bool _routeAudit(
    Map audit, String companyId, String routeId, String actorId,
  ) =>
      audit['company_id'] == companyId &&
      audit['module'] == 'routes' &&
      audit['entity_type'] == 'route' &&
      audit['entity_id'] == routeId &&
      audit['action'] == 'updated' &&
      audit['actor_user_id'] == actorId &&
      audit['old_values'] is Map &&
      audit['new_values'] is Map &&
      !MutationRpcChecks.unchanged(
        audit['old_values'], audit['new_values'],
      );
}
