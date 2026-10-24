import 'package:test/test.dart';

import '../../../scripts/security/issue_317_r44_concurrent_fixture.dart';
import '../../../scripts/security/issue_317_r44_dev_test_client.dart';

void main() {
  const company = '041a7fc8-3593-41f2-b00f-99643277b18f';
  const driver = '71ab4e54-5055-40e4-874e-009a953bae85';
  const revision = '3ef4650d-780e-4b56-8a9f-0189a4e4f4aa';
  const settlement = '00005365-53f5-46da-b6e6-3dc372257dcc';

  final companyRow = <String, dynamic>{
    'id': company,
    'base_currency_code': 'AED',
    'base_currency_fraction_digits': 2,
  };
  final driverRow = <String, dynamic>{
    'id': driver,
    'company_id': company,
    'full_name': 'sync test',
    'is_active': true,
  };
  final revisionRow = <String, dynamic>{
    'id': revision,
    'company_id': company,
    'driver_id': driver,
    'effective_from': '2026-10-01',
    'effective_to': null,
    'currency_code': 'AED',
    'currency_fraction_digits': 2,
    'amount_minor_units': 100000,
  };

  R44ConcurrentFixture? verify({
    List<Map<String, dynamic>> movements = const [],
    List<Map<String, dynamic>> expenses = const [],
    List<Map<String, dynamic>> settlements = const [],
    Map<String, dynamic>? companyOverride,
    Map<String, dynamic>? driverOverride,
    List<Map<String, dynamic>>? revisionOverride,
  }) => R44ConcurrentFixture.fromVerifiedRows(
    companyId: company,
    driverId: driver,
    company: companyOverride ?? companyRow,
    driver: driverOverride ?? driverRow,
    revisions: revisionOverride ?? [revisionRow],
    movements: movements,
    driverFundedExpenses: expenses,
    settlements: settlements,
  );

  Map<String, dynamic> audit(String event) => {
    'metadata': {'settlement_id': settlement, 'audit_event': event},
    'action': event == 'driver_settlement_created'
        ? 'created'
        : 'status_changed',
  };

  group('R4.4 isolated signed-JWT race fixture', () {
    test('allows only active, compensation-backed, zero-source QA driver', () {
      final fixture = verify();
      expect(fixture, isNotNull);
      final header = fixture!.header();
      expect(header['company_id'], company);
      expect(header['driver_id'], driver);
      expect(header['compensation_revision_id'], revision);
      expect(header['gross_salary_minor_units'], 100000);
      expect(header['net_salary_payable_minor_units'], 100000);
      expect(header['closing_driver_balance_minor_units'], 0);
      expect(fixture.requestBody()['p_items'], isEmpty);
    });

    test('refuses other drivers, currencies and changed finance sources', () {
      expect(
        verify(driverOverride: {...driverRow, 'full_name': 'real driver'}),
        isNull,
      );
      expect(
        verify(companyOverride: {...companyRow, 'base_currency_code': 'USD'}),
        isNull,
      );
      expect(
        verify(
          movements: [
            {'id': revision},
          ],
        ),
        isNull,
      );
      expect(
        verify(
          expenses: [
            {'id': revision},
          ],
        ),
        isNull,
      );
      expect(
        verify(
          revisionOverride: [
            {...revisionRow, 'amount_minor_units': 99999},
          ],
        ),
        isNull,
      );
    });

    test('refuses active overlapping settlements or repeated QA marker', () {
      expect(
        verify(
          settlements: [
            {
              'period_start': '2026-10-01',
              'period_end': '2026-10-24',
              'status': 'draft',
            },
          ],
        ),
        isNull,
      );
      expect(
        verify(
          settlements: [
            {
              'period_start': '2026-10-01',
              'period_end': '2026-10-24',
              'status': 'voided',
              'notes': r44QaRaceNote,
            },
          ],
        ),
        isNull,
      );
      expect(
        verify(
          settlements: [
            {
              'period_start': '2026-10-01',
              'period_end': '2026-10-24',
              'status': 'voided',
              'notes': 'unrelated earlier QA',
            },
          ],
        ),
        isNotNull,
      );
    });
  });

  group('R4.4 concurrent result assertions', () {
    final createdRow = <String, dynamic>{
      'id': settlement,
      'status': 'draft',
      'notes': r44QaRaceNote,
    };
    test('same draft id and exactly one audit create required', () {
      expect(
        r44RaceCreatedOnce(
          first: const R44Reply(200, settlement),
          second: const R44Reply(200, settlement),
          records: [createdRow],
          audit: [audit('driver_settlement_created')],
        ),
        isTrue,
      );
      expect(
        r44RaceCreatedOnce(
          first: const R44Reply(200, settlement),
          second: const R44Reply(409, {'code': '23505'}),
          records: [createdRow],
          audit: [audit('driver_settlement_created')],
        ),
        isFalse,
      );
      expect(
        r44RaceCreatedOnce(
          first: const R44Reply(200, settlement),
          second: const R44Reply(200, settlement),
          records: [createdRow],
          audit: [
            audit('driver_settlement_created'),
            audit('driver_settlement_created'),
          ],
        ),
        isFalse,
      );
    });

    test('Finalize can lose to Void, but audit cannot drift', () {
      final voided = <String, dynamic>{
        'id': settlement,
        'status': 'voided',
        'void_reason': r44QaVoidReason,
      };
      expect(
        r44RaceVoidedOnce(
          voidReply: const R44Reply(200, [{}]),
          finalizeReply: const R44Reply(400, {'code': '23514'}),
          records: [voided],
          audit: [
            audit('driver_settlement_created'),
            audit('driver_settlement_voided'),
          ],
          settlementId: settlement,
        ),
        isTrue,
      );
      expect(
        r44RaceVoidedOnce(
          voidReply: const R44Reply(200, [{}]),
          finalizeReply: const R44Reply(500, {'code': '40P01'}),
          records: [voided],
          audit: [
            audit('driver_settlement_created'),
            audit('driver_settlement_voided'),
          ],
          settlementId: settlement,
        ),
        isFalse,
      );
    });
  });
}
