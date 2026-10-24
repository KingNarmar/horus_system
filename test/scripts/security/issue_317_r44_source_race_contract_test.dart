import 'package:test/test.dart';

import '../../../scripts/security/issue_317_r44_dev_test_client.dart';
import '../../../scripts/security/issue_317_r44_source_race_contract.dart';

void main() {
  const companyId = '041a7fc8-3593-41f2-b00f-99643277b18f';
  const driverId = '71ab4e54-5055-40e4-874e-009a953bae85';
  const expenseId = '53ff6bd5-a255-4761-8a43-60969cebb9b1';
  const settlementId = '1dbd83ad-4e91-43b5-a284-2ed0d4b6de66';
  const revisionId = '3ef4650d-780e-4b56-8a9f-0189a4e4f4aa';
  const marker = 'r44-source-race-qa';

  const fixture = R44SourceRaceFixture(
    companyId: companyId,
    expenseId: expenseId,
    settlementId: settlementId,
    driverId: driverId,
    marker: marker,
  );

  final expense = <String, dynamic>{
    'id': expenseId,
    'company_id': companyId,
    'trip_id': 'bfb099b3-728c-442b-b3a5-58a0565f7b2a',
    'description': 'QA $marker',
    'origin_kind': 'manual',
    'is_voided': false,
    'funding_source': 'driver_cash',
    'amount_minor_units': 100,
    'expense_date': '2026-10-24',
  };
  final settlement = <String, dynamic>{
    'id': settlementId,
    'company_id': companyId,
    'driver_id': driverId,
    'status': 'draft',
    'notes': marker,
    'currency_code': 'AED',
    'currency_fraction_digits': 2,
    'compensation_revision_id': revisionId,
    'gross_salary_minor_units': 100000,
    'opening_driver_balance_minor_units': 0,
    'net_salary_payable_minor_units': 100000,
    'closing_driver_balance_minor_units': 100,
    'period_start': '2026-10-01',
    'period_end': '2026-10-24',
  };
  final item = <String, dynamic>{
    'company_id': companyId,
    'settlement_id': settlementId,
    'source_type': 'trip_expense',
    'source_id': expenseId,
    'direction': 'company_to_driver',
    'currency_code': 'AED',
    'currency_fraction_digits': 2,
    'amount_minor_units': 100,
  };
  final company = <String, dynamic>{
    'id': companyId,
    'base_currency_code': 'AED',
    'base_currency_fraction_digits': 2,
  };

  bool matches({
    Map<String, dynamic>? changeExpense,
    Map<String, dynamic>? changeSettlement,
    Map<String, dynamic>? changeCompany,
    List<Map<String, dynamic>>? changeItems,
  }) => fixture.matches(
    expense: changeExpense ?? expense,
    settlement: changeSettlement ?? settlement,
    company: changeCompany ?? company,
    items: changeItems ?? [item],
  );

  group('R4.4 source-backed race fixture preflight', () {
    test('accepts isolated non-void driver-paid captured canonical source', () {
      expect(fixture.valid, isTrue);
      expect(matches(), isTrue);
    });

    test('rejects omitted, voided, foreign or company-paid expenses', () {
      expect(matches(changeItems: []), isFalse);
      expect(matches(changeExpense: {...expense, 'is_voided': true}), isFalse);
      expect(
        matches(changeExpense: {...expense, 'company_id': revisionId}),
        isFalse,
      );
      expect(
        matches(changeExpense: {...expense, 'funding_source': 'company'}),
        isFalse,
      );
    });

    test('rejects stale Draft, outside period and wrong currency', () {
      expect(
        matches(changeSettlement: {...settlement, 'status': 'finalized'}),
        isFalse,
      );
      expect(
        matches(changeExpense: {...expense, 'expense_date': '2026-11-24'}),
        isFalse,
      );
      expect(
        matches(changeCompany: {...company, 'base_currency_code': 'USD'}),
        isFalse,
      );
      expect(
        matches(
          changeSettlement: {...settlement, 'compensation_revision_id': null},
        ),
        isFalse,
      );
    });

    test('rejects wrong source amount or duplicated provenance', () {
      expect(
        matches(
          changeItems: [
            {...item, 'amount_minor_units': 99},
          ],
        ),
        isFalse,
      );
      expect(matches(changeItems: [item, item]), isFalse);
    });
  });

  group('R4.4 concurrent source void and finalize outcome', () {
    const expenseVoided = <String, dynamic>{'id': expenseId, 'is_voided': true};
    const expenseAvailable = <String, dynamic>{
      'id': expenseId,
      'is_voided': false,
    };
    const draft = <String, dynamic>{'id': settlementId, 'status': 'draft'};
    const finalized = <String, dynamic>{
      'id': settlementId,
      'status': 'finalized',
    };

    test('void wins, stale finalize fails and creates one expense audit', () {
      expect(
        verifyR44SourceRace(
          expenseId: expenseId,
          settlementId: settlementId,
          voidReply: const R44Reply(200, {'id': expenseId}),
          finalizeReply: const R44Reply(400, {'code': 'P2815'}),
          expense: expenseVoided,
          settlement: draft,
          voidAuditDelta: 1,
          finalizeAuditDelta: 0,
        ),
        R44SourceRaceOutcome.voidWon,
      );
    });

    test('finalize wins, source void denied with no expense audit', () {
      expect(
        verifyR44SourceRace(
          expenseId: expenseId,
          settlementId: settlementId,
          voidReply: const R44Reply(400, {'code': 'P2811'}),
          finalizeReply: const R44Reply(200, [
            {'id': settlementId},
          ]),
          expense: expenseAvailable,
          settlement: finalized,
          voidAuditDelta: 0,
          finalizeAuditDelta: 1,
        ),
        R44SourceRaceOutcome.finalizeWon,
      );
    });

    test('deadlocks, double success or money/audit drift always fail', () {
      for (final invalid in [
        const R44Reply(500, {'code': '40P01'}),
        const R44Reply(500, {'code': '57014'}),
      ]) {
        expect(
          verifyR44SourceRace(
            expenseId: expenseId,
            settlementId: settlementId,
            voidReply: const R44Reply(200, {'id': expenseId}),
            finalizeReply: invalid,
            expense: expenseVoided,
            settlement: draft,
            voidAuditDelta: 1,
            finalizeAuditDelta: 0,
          ),
          R44SourceRaceOutcome.rejected,
        );
      }
      expect(
        verifyR44SourceRace(
          expenseId: expenseId,
          settlementId: settlementId,
          voidReply: const R44Reply(200, {}),
          finalizeReply: const R44Reply(200, [{}]),
          expense: expenseVoided,
          settlement: finalized,
          voidAuditDelta: 1,
          finalizeAuditDelta: 1,
        ),
        R44SourceRaceOutcome.rejected,
      );
      expect(
        verifyR44SourceRace(
          expenseId: expenseId,
          settlementId: settlementId,
          voidReply: const R44Reply(400, {'code': 'P2811'}),
          finalizeReply: const R44Reply(200, [{}]),
          expense: expenseAvailable,
          settlement: finalized,
          voidAuditDelta: 1,
          finalizeAuditDelta: 1,
        ),
        R44SourceRaceOutcome.rejected,
      );
    });
  });
}
