import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/policies/invoice_lifecycle_policy.dart';
import 'package:horus_system/features/invoices/domain/policies/invoices_permission_policy.dart';
import 'package:test/test.dart';

void main() {
  test('invoice view permission follows the approved role matrix', () {
    expect(InvoicesPermissionPolicy.canViewInvoices(CompanyRole.owner), isTrue);
    expect(InvoicesPermissionPolicy.canViewInvoices(CompanyRole.admin), isTrue);
    expect(
      InvoicesPermissionPolicy.canViewInvoices(CompanyRole.operations),
      isTrue,
    );
    expect(
      InvoicesPermissionPolicy.canViewInvoices(CompanyRole.accountant),
      isTrue,
    );
    expect(
      InvoicesPermissionPolicy.canViewInvoices(CompanyRole.viewer),
      isTrue,
    );
    expect(
      InvoicesPermissionPolicy.canViewInvoices(CompanyRole.driver),
      isFalse,
    );
  });

  test('only owner, admin, and accountant can manage invoices', () {
    for (final role in [
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    ]) {
      expect(InvoicesPermissionPolicy.canManageInvoiceDrafts(role), isTrue);
      expect(InvoicesPermissionPolicy.canIssueInvoices(role), isTrue);
      expect(InvoicesPermissionPolicy.canCancelInvoices(role), isTrue);
    }

    for (final role in [
      CompanyRole.operations,
      CompanyRole.viewer,
      CompanyRole.driver,
    ]) {
      expect(InvoicesPermissionPolicy.canManageInvoiceDrafts(role), isFalse);
      expect(InvoicesPermissionPolicy.canIssueInvoices(role), isFalse);
      expect(InvoicesPermissionPolicy.canCancelInvoices(role), isFalse);
    }
  });

  test('lifecycle policy keeps issued and paid invoices immutable', () {
    expect(InvoiceLifecyclePolicy.canEdit(InvoiceStatus.draft), isTrue);
    expect(InvoiceLifecyclePolicy.canIssue(InvoiceStatus.draft), isTrue);
    expect(InvoiceLifecyclePolicy.canCancel(InvoiceStatus.draft), isTrue);

    expect(InvoiceLifecyclePolicy.canEdit(InvoiceStatus.issued), isFalse);
    expect(InvoiceLifecyclePolicy.canCancel(InvoiceStatus.issued), isTrue);

    expect(
      InvoiceLifecyclePolicy.canEdit(InvoiceStatus.partiallyPaid),
      isFalse,
    );
    expect(
      InvoiceLifecyclePolicy.canCancel(InvoiceStatus.partiallyPaid),
      isFalse,
    );
    expect(InvoiceLifecyclePolicy.canEdit(InvoiceStatus.paid), isFalse);
    expect(InvoiceLifecyclePolicy.canCancel(InvoiceStatus.paid), isFalse);
    expect(InvoiceLifecyclePolicy.canCancel(InvoiceStatus.cancelled), isFalse);
  });
}
