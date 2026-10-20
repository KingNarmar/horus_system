import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/security/issue_327_mutation_checks.dart';
import '../../../scripts/security/verify_issue_327_mutations.dart' as preflight;

void main() {
  const companyId = '00000000-0000-0000-0000-000000000001';
  const foreignId = '00000000-0000-0000-0000-000000000002';
  const tripId = '00000000-0000-0000-0000-000000000003';
  const routeId = '00000000-0000-0000-0000-000000000004';
  const invoicedTripId = '00000000-0000-0000-0000-000000000005';
  const actorId = '00000000-0000-0000-0000-000000000006';
  const invoiceId = '00000000-0000-0000-0000-000000000007';
  const marker = 'HORUS327-ISOLATED-TEST-001';

  const fixtures = MutationFixtureIds(
    companyId: companyId,
    foreignCompanyId: foreignId,
    tripId: tripId,
    routeId: routeId,
    invoicedTripId: invoicedTripId,
    marker: marker,
  );

  Map<String, Object?> route() => {
    'id': routeId,
    'company_id': companyId,
    'notes': marker,
    'created_by': actorId,
    'is_active': true,
    'updated_at': '2026-10-20T09:00:00+00:00',
  };

  Map<String, Object?> trip({bool billed = false}) => {
    'id': billed ? invoicedTripId : tripId,
    'company_id': companyId,
    'route_id': routeId,
    'notes': marker,
    'created_by': actorId,
    'quantity_tons': 1,
    'invoice_id': billed ? invoiceId : null,
    'updated_at': '2026-10-20T09:00:00+00:00',
  };

  test('preflight has no executable write mode', () {
    expect(preflight.main, isNotNull); // Compiles the network CLI in CI.
    expect(MutationPreflightGate.allowsArguments(['--preflight']), isTrue);
    expect(MutationPreflightGate.allowsArguments(['--execute']), isFalse);
    expect(MutationPreflightGate.allowsArguments([]), isFalse);
    expect(
      MutationPreflightGate.allowsArguments(['--preflight', '--execute']),
      isFalse,
    );
  });

  test('host guard rejects Production, lookalikes and URL tricks', () {
    expect(
      MutationPreflightGate.isDevelopmentOrigin(
        Uri.parse('https://zwnfmszssxtfxkaofnhq.supabase.co'),
      ),
      isTrue,
    );
    for (final url in [
      'https://rkhmfbxlduuovlbsxhgy.supabase.co',
      'https://zwnfmszssxtfxkaofnhq.supabase.co.evil.example',
      'http://zwnfmszssxtfxkaofnhq.supabase.co',
      'https://zwnfmszssxtfxkaofnhq.supabase.co:444',
      'https://user@zwnfmszssxtfxkaofnhq.supabase.co',
      'https://zwnfmszssxtfxkaofnhq.supabase.co/auth/v1',
      'https://zwnfmszssxtfxkaofnhq.supabase.co?redirect=1',
    ]) {
      expect(
        MutationPreflightGate.isDevelopmentOrigin(Uri.parse(url)),
        isFalse,
      );
    }
  });

  test('requires distinct valid tenant and fixture IDs with unique marker', () {
    expect(fixtures.valid, isTrue);
    expect(
      const MutationFixtureIds(
        companyId: companyId,
        foreignCompanyId: companyId,
        tripId: tripId,
        routeId: routeId,
        invoicedTripId: invoicedTripId,
        marker: marker,
      ).valid,
      isFalse,
    );
    expect(
      const MutationFixtureIds(
        companyId: companyId,
        foreignCompanyId: foreignId,
        tripId: tripId,
        routeId: routeId,
        invoicedTripId: tripId,
        marker: 'production',
      ).valid,
      isFalse,
    );
  });

  test('requires real active owner or admin in one company', () {
    final membership = [
      {
        'user_id': actorId,
        'company_id': companyId,
        'is_active': true,
        'role': 'owner',
      },
    ];
    expect(
      MutationPreflightChecks.activeAuthorizedMember(
        membership,
        actorId,
        companyId,
        foreignId,
      ),
      isTrue,
    );
    expect(
      MutationPreflightChecks.activeAuthorizedMember(
        [
          {...membership.single, 'role': 'viewer'},
        ],
        actorId,
        companyId,
        foreignId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.activeAuthorizedMember(
        [
          ...membership,
          {...membership.single, 'company_id': foreignId, 'role': 'viewer'},
        ],
        actorId,
        companyId,
        foreignId,
      ),
      isFalse,
    );
  });

  test('accepts only exact Route marker, ownership and active row', () {
    expect(
      MutationPreflightChecks.isolatedRoute([route()], fixtures, actorId),
      isTrue,
    );
    expect(
      MutationPreflightChecks.isolatedRoute(
        [
          {...route(), 'notes': 'Live customer route'},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedRoute(
        [
          {...route(), 'company_id': foreignId},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedRoute(
        [
          {...route(), 'created_by': null},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedRoute(
        [
          {...route(), 'is_active': false},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
  });

  test('blocks billed, unrelated or non-owned operational fixture', () {
    expect(
      MutationPreflightChecks.isolatedTrip([trip()], fixtures, actorId),
      isTrue,
    );
    expect(
      MutationPreflightChecks.isolatedTrip(
        [trip(billed: true)],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedTrip(
        [
          {...trip(), 'route_id': foreignId},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedTrip(
        [
          {...trip(), 'quantity_tons': 0},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedTrip(
        [
          {...trip(), 'created_by': foreignId},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
  });

  test('invoiced fixture must be separately tagged and actually linked', () {
    expect(
      MutationPreflightChecks.isolatedInvoicedTrip(
        [trip(billed: true)],
        fixtures,
        actorId,
      ),
      isTrue,
    );
    expect(
      MutationPreflightChecks.isolatedInvoicedTrip(
        [
          {...trip(billed: true), 'invoice_id': null},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
    expect(
      MutationPreflightChecks.isolatedInvoicedTrip(
        [
          {...trip(billed: true), 'notes': 'Ordinary trip'},
        ],
        fixtures,
        actorId,
      ),
      isFalse,
    );
  });

  test('denial requires exact PostgREST code and non-success status', () {
    expect(
      MutationRpcChecks.denied(
        const MutationRpcReply(403, {'code': 'P3431'}),
        'P3431',
      ),
      isTrue,
    );
    expect(
      MutationRpcChecks.denied(
        const MutationRpcReply(200, {'code': 'P3431'}),
        'P3431',
      ),
      isFalse,
    );
    expect(
      MutationRpcChecks.denied(
        const MutationRpcReply(403, {'code': 'P3414'}),
        'P3431',
      ),
      isFalse,
    );
  });

  test('legacy operations response must redact all monetary fields', () {
    final redacted = {
      'id': tripId,
      'company_id': companyId,
      'freight_price': null,
      'agreed_freight_rate_per_ton': null,
      'total_expenses': null,
    };
    expect(
      MutationRpcChecks.operationalSnapshot(
        MutationRpcReply(200, redacted),
        companyId,
        tripId,
      ),
      isTrue,
    );
    expect(
      MutationRpcChecks.operationalSnapshot(
        MutationRpcReply(200, {...redacted, 'freight_price': 20}),
        companyId,
        tripId,
      ),
      isFalse,
    );
    expect(
      MutationRpcChecks.operationalSnapshot(
        MutationRpcReply(200, {...redacted}..remove('total_expenses')),
        companyId,
        tripId,
      ),
      isFalse,
    );
  });

  test('finance response needs actual authorized monetary values', () {
    final response = {
      'id': tripId,
      'company_id': companyId,
      'freight_price': 25,
      'agreed_freight_rate_per_ton': 5,
      'total_expenses': 0,
    };
    expect(
      MutationRpcChecks.financeSnapshot(
        MutationRpcReply(200, response),
        companyId,
        tripId,
      ),
      isTrue,
    );
    expect(
      MutationRpcChecks.financeSnapshot(
        MutationRpcReply(200, {
          ...response,
          'agreed_freight_rate_per_ton': null,
        }),
        companyId,
        tripId,
      ),
      isFalse,
    );
  });

  test('read-after-denial must detect nested data changes', () {
    final before = {
      'updated_at': 'old',
      'financial': {
        'rate': 10,
        'expenses': [1, 2],
      },
    };
    expect(
      MutationRpcChecks.unchanged(before, {
        'financial': {
          'expenses': [1, 2],
          'rate': 10,
        },
        'updated_at': 'old',
      }),
      isTrue,
    );
    expect(
      MutationRpcChecks.unchanged(before, {
        'updated_at': 'new',
        'financial': {
          'rate': 10,
          'expenses': [1, 2],
        },
      }),
      isFalse,
    );
  });

  test('pricing success needs correlated server audit evidence', () {
    final audit = {
      'company_id': companyId,
      'entity_id': tripId,
      'module': 'trips',
      'entity_type': 'trip',
      'action': 'updated',
      'actor_user_id': actorId,
      'old_values': {'commercial_amount': 10},
      'new_values': {'commercial_amount': 20},
      'metadata': {'financial_terms_changed': true},
    };
    expect(
      MutationRpcChecks.financialAudit(
        [audit],
        companyId: companyId,
        tripId: tripId,
        actorUserId: actorId,
      ),
      isTrue,
    );
    expect(
      MutationRpcChecks.financialAudit(
        [
          {...audit, 'company_id': foreignId},
        ],
        companyId: companyId,
        tripId: tripId,
        actorUserId: actorId,
      ),
      isFalse,
    );
    expect(
      MutationRpcChecks.financialAudit(
        [
          {
            ...audit,
            'new_values': {'commercial_amount': 10},
          },
        ],
        companyId: companyId,
        tripId: tripId,
        actorUserId: actorId,
      ),
      isFalse,
    );
  });
}
