import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/security/issue_327_financial_read_verifier.dart';

void main() {
  const ownCompany = '00000000-0000-0000-0000-000000000001';
  const foreignCompany = '00000000-0000-0000-0000-000000000002';
  const customerId = '00000000-0000-0000-0000-000000000003';
  const driverId = '00000000-0000-0000-0000-000000000004';

  Future<List<bool>> runRole(
    String role, {
    bool leakDashboard = false,
    bool leakOperational = false,
    bool hasFixture = true,
    List<String>? skips,
  }) async {
    final outcomes = <bool>[];
    final finance = role == 'owner' || role == 'admin' || role == 'accountant';
    final driver = role == 'driver';

    Future<FinancialRpcReply> rpc(
      String name,
      Map<String, Object?> params,
    ) async {
      final companyId = params['p_company_id'];
      final foreign = companyId != ownCompany;
      String? deniedCode;
      if (name == 'get_dashboard_source') {
        deniedCode = foreign || driver ? 'P2910' : null;
      } else if (name == 'get_customer_statement_source') {
        deniedCode = foreign || !finance ? 'P2810' : null;
      } else if (name == 'get_driver_balance_checkpoint' ||
          name == 'get_driver_balance_checkpoint_v2') {
        deniedCode = foreign || !finance ? '42501' : null;
      } else {
        final operational = name == 'get_operational_trip_reports_source';
        deniedCode = foreign || (operational ? driver : !finance)
            ? 'P3010'
            : null;
      }
      if (deniedCode != null) {
        return FinancialRpcReply(403, {'code': deniedCode});
      }
      if (name == 'get_dashboard_source') {
        return FinancialRpcReply(200, {
          'company': {'company_id': ownCompany},
          'metrics': {'today_trips': 2, 'unpaid_invoices': finance ? 3 : 0},
          'financial': {
            'revenue_minor_units': finance || leakDashboard ? 100 : 0,
            'trip_expenses_minor_units': finance ? 10 : 0,
            'company_expenses_minor_units': finance ? 5 : 0,
          },
          'validation': {'financial_currency_mismatch_count': 0},
        });
      }
      if (name == 'get_customer_statement_source') {
        return FinancialRpcReply(200, {
          'company': {'company_id': ownCompany},
          'customer': {'customer_id': customerId},
          'movements': <Object>[],
        });
      }
      if (name == 'get_driver_balance_checkpoint' ||
          name == 'get_driver_balance_checkpoint_v2') {
        return const FinancialRpcReply(200, [
          {'settlement_id': 'fixture', 'closing_driver_balance': 15},
        ]);
      }
      return FinancialRpcReply(200, {
        'company': {'company_id': ownCompany},
        'rows': [
          {
            'trip_id': 'fixture',
            if (leakOperational &&
                name == 'get_operational_trip_reports_source')
              'freight_price': 100,
          },
        ],
      });
    }

    await verifyFinancialReadAccess(
      role: role,
      companyId: ownCompany,
      foreignCompanyId: foreignCompany,
      rpc: rpc,
      check: (label, assertion) async {
        outcomes.add(await assertion());
      },
      skip: (label) => skips?.add(label),
      fixtureId: (fixture) async {
        if (!hasFixture) return null;
        if (fixture == FinancialReadFixtures.customer) return customerId;
        if (fixture == FinancialReadFixtures.finalizedDriver) return driverId;
        return null;
      },
    );
    return outcomes;
  }

  test('finance roles can read authorized financial RPCs', () async {
    for (final role in ['owner', 'admin', 'accountant']) {
      final outcomes = await runRole(role);
      expect(outcomes, hasLength(16));
      expect(outcomes, everyElement(isTrue));
    }
  });

  test('operations and viewer receive no financial data', () async {
    for (final role in ['operations', 'viewer']) {
      final outcomes = await runRole(role);
      expect(outcomes, hasLength(16));
      expect(outcomes, everyElement(isTrue));
    }
  });

  test('driver cannot access any report or dashboard RPC', () async {
    final outcomes = await runRole('driver');
    expect(outcomes, hasLength(16));
    expect(outcomes, everyElement(isTrue));
  });

  test('a monetary field in operational report JSON is detected', () async {
    final outcomes = await runRole('operations', leakOperational: true);
    expect(outcomes, contains(isFalse));
  });

  test('a financial Dashboard JSON leak is detected', () async {
    final outcomes = await runRole('viewer', leakDashboard: true);
    expect(outcomes, contains(isFalse));
  });

  test('fixture lookup is company-scoped and requires canonical settlement', () async {
    final id = await readFinancialFixtureId(
      fixture: FinancialReadFixtures.finalizedDriver,
      companyId: ownCompany,
      fetch: (table, query) async {
        expect(table, 'driver_settlements');
        expect(query['company_id'], 'eq.$ownCompany');
        expect(query['status'], 'eq.finalized');
        expect(query['closing_driver_balance_minor_units'], 'not.is.null');
        expect(query['currency_code'], 'not.is.null');
        expect(query['currency_fraction_digits'], 'not.is.null');
        return [
          {'driver_id': driverId},
        ];
      },
    );
    expect(id, driverId);
  });

  test('missing positive financial fixtures are explicitly skipped', () async {
    final skipped = <String>[];
    final outcomes = await runRole(
      'accountant',
      hasFixture: false,
      skips: skipped,
    );
    expect(outcomes, hasLength(13));
    expect(skipped, hasLength(3));
    expect(outcomes, everyElement(isTrue));
  });
}
