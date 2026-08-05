import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/invoices/data/mappers/invoice_draft_write_mapper.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:test/test.dart';

void main() {
  test('maps only trusted draft intent to RPC parameters', () {
    final currency = CurrencyCode.tryParse('AED')!;
    final draft = InvoiceDraftData(
      companyId: 'company-1',
      customer: const InvoiceCustomerSnapshot(
        companyId: 'company-1',
        customerId: 'customer-1',
        name: 'Client-provided name must not be persisted',
      ),
      currency: currency,
      lines: [
        InvoiceTripLine(
          tripId: 'trip-1',
          loadingOrderNumber: 'client-snapshot',
          amount: Money(minorUnits: 10000, currency: currency),
        ),
      ],
      totals: InvoiceTotals(
        subtotal: Money(minorUnits: 10000, currency: currency),
        discount: Money(minorUnits: 500, currency: currency),
        taxableAmount: Money(minorUnits: 9500, currency: currency),
        taxRate: TaxRate.tryCreate(500)!,
        taxAmount: Money(minorUnits: 475, currency: currency),
        grandTotal: Money(minorUnits: 9975, currency: currency),
      ),
      issueDate: InvoiceDate.fromDateTime(DateTime.utc(2026, 8, 5)),
      dueDate: InvoiceDate.fromDateTime(DateTime.utc(2026, 9, 4)),
      notes: 'Draft note',
    );

    final params = draft.toWriteModel().createParams();

    expect(params['p_company_id'], 'company-1');
    expect(params['p_customer_id'], 'customer-1');
    expect(params['p_trip_ids'], ['trip-1']);
    expect(params['p_discount_minor_units'], 500);
    expect(params['p_tax_rate_basis_points'], 500);
    expect(params['p_issue_date'], '2026-08-05');
    expect(params['p_due_date'], '2026-09-04');
    expect(params['p_notes'], 'Draft note');

    expect(params, isNot(contains('actor_role')));
    expect(params, isNot(contains('currency_code')));
    expect(params, isNot(contains('customer_name')));
    expect(params, isNot(contains('subtotal_minor_units')));
    expect(params, isNot(contains('total_minor_units')));
    expect(params, isNot(contains('loading_order_number')));
  });
}
