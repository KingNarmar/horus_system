import 'package:horus_system/features/audit/data/models/audit_log_model.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:test/test.dart';

void main() {
  group('AuditLogModel semantic mapping', () {
    test('keeps invoice issued, payment registered and invitation accepted', () {
      final cases = [
        ('invoices', 'invoice', 'issued', AuditModule.invoices,
            AuditEntityType.invoice, AuditAction.issued),
        ('payments', 'payment', 'registered', AuditModule.payments,
            AuditEntityType.payment, AuditAction.registered),
        ('company_users', 'company_invitation', 'accepted',
            AuditModule.companyUsers, AuditEntityType.companyInvitation,
            AuditAction.accepted),
        ('companies', 'company', 'created', AuditModule.companies,
            AuditEntityType.company, AuditAction.created),
        ('expenses', 'expense_ledger_entry', 'voided', AuditModule.expenses,
            AuditEntityType.expenseLedgerEntry, AuditAction.voided),
      ];
      for (final entry in cases) {
        final log = _model(
          module: entry.$1, entityType: entry.$2, action: entry.$3,
        ).toEntity();
        expect(log.module, entry.$4);
        expect(log.entityType, entry.$5);
        expect(log.action, entry.$6);
        expect(log.rawModule, entry.$1);
        expect(log.rawEntityType, entry.$2);
        expect(log.rawAction, entry.$3);
      }
    });

    test('unknown keys preserve exact original values without false semantics', () {
      final log = _model(
        module: 'Future_Module',
        entityType: 'future_entity',
        action: 'future_action',
      ).toEntity();
      expect(log.module, AuditModule.unknown);
      expect(log.entityType, AuditEntityType.unknown);
      expect(log.action, AuditAction.unknown);
      expect(log.module, isNot(AuditModule.customers));
      expect(log.entityType, isNot(AuditEntityType.customer));
      expect(log.action, isNot(AuditAction.updated));
      expect(log.rawModule, 'Future_Module');
      expect(log.rawEntityType, 'future_entity');
      expect(log.rawAction, 'future_action');
    });

    test('legacy case normalization never modifies stored semantic identity', () {
      final log = _model(
        module: '  DRIVERS  ', entityType: ' Driver ', action: '  UPDATED ',
      ).toEntity();
      expect(log.module, AuditModule.drivers);
      expect(log.entityType, AuditEntityType.driver);
      expect(log.action, AuditAction.updated);
      expect(log.rawModule, '  DRIVERS  ');
      expect(log.rawEntityType, ' Driver ');
      expect(log.rawAction, '  UPDATED ');
    });
  });
}

AuditLogModel _model({
  required String module,
  required String entityType,
  required String action,
}) => AuditLogModel(
  id: 'event-id', companyId: 'company-id', module: module,
  entityType: entityType, entityId: 'entity-id', action: action,
  description: 'event_description', createdAt: DateTime.utc(2026, 11, 8),
);
