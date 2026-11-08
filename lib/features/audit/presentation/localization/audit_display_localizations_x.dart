import '../../../../l10n/app_localizations.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../domain/entities/audit_action.dart';

extension AuditDisplayLocalizationsX on AppLocalizations {
  String auditActionDisplayLabel(AuditAction action) {
    return switch (action) {
      AuditAction.created => customerAuditActionCreated,
      AuditAction.updated => customerAuditActionUpdated,
      AuditAction.deactivated => customerAuditActionDeactivated,
      AuditAction.reactivated => customerAuditActionReactivated,
      AuditAction.statusChanged => customerAuditActionStatusChanged,
      AuditAction.accepted => auditActionAccepted,
      AuditAction.cancelled => auditActionCancelled,
      AuditAction.issued => auditActionIssued,
      AuditAction.paymentStatusChanged => auditActionPaymentStatusChanged,
      AuditAction.registered => auditActionRegistered,
      AuditAction.resent => auditActionResent,
      AuditAction.revoked => auditActionRevoked,
      AuditAction.sent => auditActionSent,
      AuditAction.voided => auditActionVoided,
      AuditAction.unknown => customerNotAvailable,
    };
  }

  String auditActionValueDisplayLabel(String? rawAction) {
    final action = _auditActionFromValue(rawAction);
    return action == null
        ? customerNotAvailable
        : auditActionDisplayLabel(action);
  }

  String auditRoleDisplayLabel(String? rawRole) {
    final role = _companyRoleFromValue(rawRole);
    return switch (role) {
      CompanyRole.owner => roleOwner,
      CompanyRole.admin => roleAdmin,
      CompanyRole.operations => roleOperations,
      CompanyRole.accountant => roleAccountant,
      CompanyRole.viewer => roleViewer,
      CompanyRole.driver => roleDriver,
      null => customerNotAvailable,
    };
  }
}

AuditAction? _auditActionFromValue(String? rawAction) {
  final normalized = rawAction?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;

  for (final action in AuditAction.values) {
    if (action.value == normalized) return action;
  }

  return null;
}

CompanyRole? _companyRoleFromValue(String? rawRole) {
  final normalized = rawRole?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;

  for (final role in CompanyRole.values) {
    if (role.value == normalized) return role;
  }

  return null;
}
