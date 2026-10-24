// Issue #317 R4.4: pure fail-closed source-backed race fixture assertions.
// No Supabase/network; test code only (must never be imported by lib/).
import 'issue_317_r44_dev_test_client.dart';

final class R44SourceRaceFixture {
  final String companyId;
  final String expenseId;
  final String settlementId;
  final String driverId;
  final String marker;

  const R44SourceRaceFixture({
    required this.companyId,
    required this.expenseId,
    required this.settlementId,
    required this.driverId,
    required this.marker,
  });

  bool get valid =>
      isR44Uuid(companyId) &&
      isR44Uuid(expenseId) &&
      isR44Uuid(settlementId) &&
      isR44Uuid(driverId) &&
      marker.length >= 12 &&
      expenseId != settlementId;

  bool matches({
    required Map<String, dynamic> expense,
    required Map<String, dynamic> settlement,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> company,
  }) {
    if (!valid ||
        expense['id'] != expenseId ||
        expense['company_id'] != companyId ||
        expense['origin_kind'] != 'manual' ||
        expense['is_voided'] != false ||
        !{'driver_cash', 'driver_advance'}.contains(expense['funding_source']) ||
        expense['trip_id'] == null ||
        !isR44Uuid(expense['trip_id'].toString()) ||
        !(expense['description']?.toString() ?? '').contains(marker) ||
        settlement['id'] != settlementId ||
        settlement['company_id'] != companyId ||
        settlement['driver_id'] != driverId ||
        settlement['status'] != 'draft' ||
        !(settlement['notes']?.toString() ?? '').contains(marker) ||
        company['id'] != companyId ||
        company['base_currency_code'] != 'AED' ||
        company['base_currency_fraction_digits'].toString() != '2' ||
        settlement['currency_code'] != 'AED' ||
        settlement['currency_fraction_digits'].toString() != '2' ||
        !isR44Uuid(settlement['compensation_revision_id']?.toString() ?? '') ||
        settlement['gross_salary_minor_units'] == null ||
        settlement['opening_driver_balance_minor_units'] == null ||
        settlement['net_salary_payable_minor_units'] == null ||
        settlement['closing_driver_balance_minor_units'] == null ||
        items.where((item) =>
          item['source_type'] == 'trip_expense' &&
          item['source_id'] == expenseId &&
          item['company_id'] == companyId &&
          item['settlement_id'] == settlementId &&
          item['direction'] == 'company_to_driver' &&
          item['currency_code'] == 'AED' &&
          item['currency_fraction_digits'].toString() == '2' &&
          item['amount_minor_units'].toString() ==
              expense['amount_minor_units'].toString()).length != 1) {
      return false;
    }
    final start = settlement['period_start']?.toString();
    final end = settlement['period_end']?.toString();
    final expenseDate = expense['expense_date']?.toString();
    return start != null &&
        end != null &&
        expenseDate != null &&
        start.compareTo(expenseDate) <= 0 &&
        expenseDate.compareTo(end) <= 0;
  }
}

enum R44SourceRaceOutcome {
  voidWon,
  finalizeWon,
  rejected,
}

R44SourceRaceOutcome verifyR44SourceRace({
  required R44Reply voidReply,
  required R44Reply finalizeReply,
  required Map<String, dynamic> expense,
  required Map<String, dynamic> settlement,
  required int voidAuditDelta,
  required int finalizeAuditDelta,
}) {
  if (voidReply.ok == finalizeReply.ok) {
    return R44SourceRaceOutcome.rejected;
  }
  // Reject deadlock, timeout, conflict, transport or all unknown errors.
  if (voidReply.ok &&
      finalizeReply.sqlState != 'P2812' &&
      finalizeReply.sqlState != 'P2815') {
    return R44SourceRaceOutcome.rejected;
  }
  if (finalizeReply.ok && voidReply.sqlState != 'P2811') {
    return R44SourceRaceOutcome.rejected;
  }
  if (voidReply.ok &&
      expense['is_voided'] == true &&
      settlement['status'] == 'draft' &&
      voidAuditDelta == 1 &&
      finalizeAuditDelta == 0) {
    return R44SourceRaceOutcome.voidWon;
  }
  if (finalizeReply.ok &&
      expense['is_voided'] == false &&
      settlement['status'] == 'finalized' &&
      voidAuditDelta == 0 &&
      finalizeAuditDelta == 1) {
    return R44SourceRaceOutcome.finalizeWon;
  }
  return R44SourceRaceOutcome.rejected;
}
