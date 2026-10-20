import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/security/issue_327_mutation_checks.dart';

void main() {
  const companyId = '00000000-0000-0000-0000-000000000001';
  const foreignId = '00000000-0000-0000-0000-000000000002';
  const tripId = '00000000-0000-0000-0000-000000000003';
  const routeId = '00000000-0000-0000-0000-000000000004';
  const invoicedTripId = '00000000-0000-0000-0000-000000000005';
  const actorId = '00000000-0000-0000-0000-000000000006';
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

  Map<String, Object?> routeCreationAudit() => {
    'company_id': companyId,
    'module': 'routes',
    'entity_type': 'route',
    'entity_id': routeId,
    'action': 'created',
    'actor_user_id': actorId,
    'actor_role': 'owner',
    'old_values': null,
    'new_values': {'id': routeId, 'company_id': companyId, 'notes': marker},
    'metadata': {'audit_event': 'route_created'},
    'created_at': '2026-10-20T09:00:00+00:00',
  };

  bool isolatedRoute(Map<String, Object?> value, {Object? creationAudits}) =>
      MutationPreflightChecks.isolatedRoute(
        [value],
        fixtures,
        actorId,
        creationAudits: creationAudits ?? [routeCreationAudit()],
      );

  test('accepts signed-in Route creator backed by exact server audit', () {
    expect(isolatedRoute(route()), isTrue);
    expect(isolatedRoute({...route(), 'created_by': null}), isTrue);
    expect(
      isolatedRoute(
        {...route(), 'created_by': null},
        creationAudits: [
          {...routeCreationAudit(), 'actor_role': 'admin'},
        ],
      ),
      isTrue,
    );
  });

  test('Route row must be isolated, tagged and active', () {
    expect(
      isolatedRoute({...route(), 'notes': 'Live customer route'}),
      isFalse,
    );
    expect(isolatedRoute({...route(), 'company_id': foreignId}), isFalse);
    expect(isolatedRoute({...route(), 'created_by': foreignId}), isFalse);
    expect(isolatedRoute({...route(), 'is_active': false}), isFalse);
    expect(isolatedRoute({...route(), 'updated_at': 'invalid'}), isFalse);
  });

  test(
    'Route creation audit must prove the exact actor and marked fixture',
    () {
      final original = routeCreationAudit();
      final invalidAudits = <Map<String, Object?>>[
        {...original, 'company_id': foreignId},
        {...original, 'module': 'trips'},
        {...original, 'entity_type': 'trip'},
        {...original, 'entity_id': tripId},
        {...original, 'action': 'updated'},
        {...original, 'actor_user_id': foreignId},
        {...original, 'actor_role': 'viewer'},
        {
          ...original,
          'old_values': {'notes': 'old'},
        },
        {
          ...original,
          'new_values': {
            'id': tripId,
            'company_id': companyId,
            'notes': marker,
          },
        },
        {
          ...original,
          'new_values': {
            'id': routeId,
            'company_id': foreignId,
            'notes': marker,
          },
        },
        {
          ...original,
          'new_values': {
            'id': routeId,
            'company_id': companyId,
            'notes': 'other-route',
          },
        },
        {
          ...original,
          'metadata': {'audit_event': 'trip_created'},
        },
        {...original, 'created_at': 'invalid'},
      ];
      for (final invalid in invalidAudits) {
        expect(
          isolatedRoute(
            {...route(), 'created_by': null},
            creationAudits: [invalid],
          ),
          isFalse,
        );
      }
      expect(isolatedRoute(route(), creationAudits: <Object>[]), isFalse);
      expect(
        isolatedRoute(route(), creationAudits: [original, original]),
        isFalse,
      );
      expect(
        MutationPreflightChecks.isolatedRoute(
          [route()],
          fixtures,
          actorId,
          creationAudits: null,
        ),
        isFalse,
      );
    },
  );
}
