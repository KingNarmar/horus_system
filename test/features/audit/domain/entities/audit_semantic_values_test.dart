import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:test/test.dart';

void main() {
  test('distinct historical audit actions keep their own semantic keys', () {
    expect(AuditAction.issued.value, 'issued');
    expect(AuditAction.cancelled.value, 'cancelled');
    expect(AuditAction.paymentStatusChanged.value, 'payment_status_changed');
    expect(AuditAction.registered.value, 'registered');
    expect(AuditAction.accepted.value, 'accepted');
    expect(AuditAction.resent.value, 'resent');
    expect(AuditAction.revoked.value, 'revoked');
    expect(AuditAction.sent.value, 'sent');
    expect(AuditAction.voided.value, 'voided');
    expect(AuditAction.unknown.value, 'unknown');
  });

  test('company and ledger entities do not masquerade as customers', () {
    expect(AuditModule.companies.value, 'companies');
    expect(AuditModule.unknown.value, 'unknown');
    expect(AuditEntityType.company.value, 'company');
    expect(AuditEntityType.companyInvitation.value, 'company_invitation');
    expect(AuditEntityType.expenseLedgerEntry.value, 'expense_ledger_entry');
    expect(AuditEntityType.unknown.value, 'unknown');
  });
}
