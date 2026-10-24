// Pure fixture contract for Development-only Issue #317 R4.4 race tests.
// Does not calculate production settlement amounts or call any APIs.
// It refuses to operate unless all financial inputs match an isolated,
// zero-source fixture whose expected snapshot is explicitly fixed.
import 'issue_317_r44_dev_test_client.dart';

const r44QaPeriodStart = '2026-10-01';
const r44QaPeriodEnd = '2026-10-24';
const r44QaRaceNote = 'R4.4 Concurrent Signed QA';
const r44QaVoidReason = 'R4.4 concurrent finalize-void QA';

final class R44ConcurrentFixture {
  final String companyId;
  final String driverId;
  final String compensationRevisionId;

  const R44ConcurrentFixture({
    required this.companyId,
    required this.driverId,
    required this.compensationRevisionId,
  });

  static R44ConcurrentFixture? fromVerifiedRows({
    required String companyId,
    required String driverId,
    required Map<String, dynamic> company,
    required Map<String, dynamic> driver,
    required List<Map<String, dynamic>> revisions,
    required List<Map<String, dynamic>> movements,
    required List<Map<String, dynamic>> driverFundedExpenses,
    required List<Map<String, dynamic>> settlements,
  }) {
    if (!isR44Uuid(companyId) ||
        !isR44Uuid(driverId) ||
        company['id'] != companyId ||
        company['base_currency_code'] != 'AED' ||
        company['base_currency_fraction_digits'].toString() != '2' ||
        driver['company_id'] != companyId ||
        driver['id'] != driverId ||
        driver['is_active'] != true ||
        driver['full_name']?.toString().toLowerCase() != 'sync test' ||
        movements.isNotEmpty ||
        driverFundedExpenses.isNotEmpty) {
      return null;
    }
    final validRevisions = revisions.where((row) =>
        row['company_id'] == companyId &&
        row['driver_id'] == driverId &&
        isR44Uuid(row['id']?.toString() ?? '') &&
        row['effective_from'] is String &&
        (row['effective_from'] as String).compareTo(r44QaPeriodStart) <= 0 &&
        (row['effective_to'] == null ||
            (row['effective_to'] is String &&
                (row['effective_to'] as String).compareTo(r44QaPeriodEnd) >= 0)) &&
        row['currency_code'] == 'AED' &&
        row['currency_fraction_digits'].toString() == '2' &&
        row['amount_minor_units'].toString() == '100000').toList();
    if (validRevisions.length != 1) return null;
    for (final row in settlements) {
      final start = row['period_start'];
      final end = row['period_end'];
      if (start is! String || end is! String) return null;
      if (row['notes'] == r44QaRaceNote ||
          (row['status'] != 'voided' &&
              start.compareTo(r44QaPeriodEnd) <= 0 &&
              end.compareTo(r44QaPeriodStart) >= 0)) {
        return null;
      }
    }
    return R44ConcurrentFixture(
      companyId: companyId,
      driverId: driverId,
      compensationRevisionId: validRevisions.single['id'] as String,
    );
  }

  Map<String, Object?> header() {
    final money = <String, Object?>{
      'opening_driver_balance': '0.00',
      'opening_driver_balance_minor_units': 0,
      'advances_total': '0.00',
      'advances_total_minor_units': 0,
      'driver_paid_trip_expenses_total': '0.00',
      'driver_paid_trip_expenses_total_minor_units': 0,
      'returned_cash_total': '0.00',
      'returned_cash_total_minor_units': 0,
      'deductions_total': '0.00',
      'deductions_total_minor_units': 0,
      'settlement_deductions_total': '0.00',
      'settlement_deductions_total_minor_units': 0,
      'salary_deductions_total': '0.00',
      'salary_deductions_total_minor_units': 0,
      'balance_deduction_applied': '0.00',
      'balance_deduction_applied_minor_units': 0,
      'closing_driver_balance': '0.00',
      'closing_driver_balance_minor_units': 0,
      'gross_salary': '1000.00',
      'gross_salary_minor_units': 100000,
      'net_salary_payable': '1000.00',
      'net_salary_payable_minor_units': 100000,
    };
    return {
      'company_id': companyId,
      'driver_id': driverId,
      'period_start': r44QaPeriodStart,
      'period_end': r44QaPeriodEnd,
      'compensation_revision_id': compensationRevisionId,
      'currency_code': 'AED',
      'currency_fraction_digits': 2,
      'status': 'draft',
      ...money,
      'notes': r44QaRaceNote,
    };
  }

  Map<String, Object?> requestBody() => {
    'p_company_id': companyId,
    'p_header': header(),
    'p_items': <Object>[],
  };
}

bool r44RaceCreatedOnce({
  required R44Reply first,
  required R44Reply second,
  required List<Map<String, dynamic>> records,
  required List<Map<String, dynamic>> audit,
}) {
  if (!first.ok ||
      !second.ok ||
      first.body is! String ||
      first.body != second.body ||
      !isR44Uuid(first.body as String) ||
      records.length != 1 ||
      records.single['id'] != first.body ||
      records.single['status'] != 'draft' ||
      records.single['notes'] != r44QaRaceNote) {
    return false;
  }
  return audit.where((row) =>
          row['metadata'] is Map &&
          (row['metadata'] as Map)['settlement_id'] == first.body &&
          (row['metadata'] as Map)['audit_event'] ==
              'driver_settlement_created').length ==
      1;
}

bool r44RaceVoidedOnce({
  required R44Reply voidReply,
  required R44Reply finalizeReply,
  required List<Map<String, dynamic>> records,
  required List<Map<String, dynamic>> audit,
  required String settlementId,
}) {
  if (!voidReply.ok ||
      voidReply.rows.length != 1 ||
      records.length != 1 ||
      records.single['status'] != 'voided' ||
      records.single['void_reason'] != r44QaVoidReason ||
      records.single['id'] != settlementId) {
    return false;
  }
  // Finalization can lose the race to Void; then its trigger must reject the
  // stale transition. Never treat an arbitrary network error as acceptable.
  if (!finalizeReply.ok &&
      !{'23514', 'P2814', 'P2811'}
          .contains(finalizeReply.sqlState)) {
    return false;
  }
  if (finalizeReply.ok && finalizeReply.rows.length != 1) return false;
  final events = audit.where((row) =>
          row['metadata'] is Map &&
          (row['metadata'] as Map)['settlement_id'] == settlementId).toList();
  final kinds = events
      .map((row) => (row['metadata'] as Map)['audit_event'])
      .toList();
  return kinds.where((v) => v == 'driver_settlement_created').length == 1 &&
      kinds.where((v) => v == 'driver_settlement_voided').length == 1 &&
      kinds.where((v) => v == 'driver_settlement_finalized').length ==
          (finalizeReply.ok ? 1 : 0) &&
      kinds.length == (finalizeReply.ok ? 3 : 2);
}
