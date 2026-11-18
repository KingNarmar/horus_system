import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_details_state.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_pdf_state.dart';
import 'package:horus_system/features/invoices/presentation/widgets/invoice_details_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('authorized invoice PDF buttons forward preview intent', (
    tester,
  ) async {
    await _setSurfaceSize(tester, const Size(900, 1000));
    InvoicePdfAction? requested;
    await _pumpLocalized(
      tester,
      child: InvoiceDetailsDialog(
        state: _loadedState(),
        onRetry: () {},
        onIssue: (_, _) async => false,
        onCancel: (_, _) async => false,
        onPdfAction: (action) => requested = action,
      ),
    );

    expect(
      find.byKey(const ValueKey('invoicePdfPreviewActionButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoicePdfSaveActionButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoicePdfPrintActionButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoicePdfShareActionButton')),
      findsOneWidget,
    );

    final preview = find.byKey(const ValueKey('invoicePdfPreviewActionButton'));
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    expect(requested, InvoicePdfAction.preview);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unprivileged invoice role has no PDF actions', (tester) async {
    await _setSurfaceSize(tester, const Size(900, 1000));
    await _pumpLocalized(
      tester,
      child: InvoiceDetailsDialog(
        state: _loadedState(role: CompanyRole.viewer),
        onRetry: () {},
        onIssue: (_, _) async => false,
        onCancel: (_, _) async => false,
        onPdfAction: (_) {},
      ),
    );

    expect(
      find.byKey(const ValueKey('invoicePdfPreviewActionButton')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('invoicePdfSaveActionButton')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('invoicePdfPrintActionButton')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('invoicePdfShareActionButton')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy PDF export disables financial actions with Arabic UX', (
    tester,
  ) async {
    await _setSurfaceSize(tester, const Size(900, 1000));
    await _pumpLocalized(
      tester,
      locale: const Locale('ar'),
      settle: false,
      child: InvoiceDetailsDialog(
        state: _loadedState(),
        onRetry: () {},
        onIssue: (_, _) async => false,
        onCancel: (_, _) async => false,
        onPdfAction: (_) {},
        isPdfBusy: true,
      ),
    );

    expect(find.text('جاري تجهيز PDF...'), findsOneWidget);
    final preview = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('invoicePdfPreviewActionButton')),
    );
    final issue = tester.widget<FilledButton>(
      find.byKey(const ValueKey('invoiceIssueActionButton')),
    );
    expect(preview.onPressed, isNull);
    expect(issue.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

InvoiceDetailsLoaded _loadedState({CompanyRole role = CompanyRole.accountant}) {
  final currency = CurrencyCode.tryParse('AED')!;
  final amount = Money(minorUnits: 12000000, currency: currency);
  final zero = Money(minorUnits: 0, currency: currency);
  return InvoiceDetailsLoaded(
    invoiceCreatedAt: BusinessLocalDateTime(
      year: 2026,
      month: 8,
      day: 7,
      hour: 4,
      minute: 0,
    ),
    currentCompanyContext: CurrentCompanyContext(
      company: const Company(
        id: 'company-1',
        name: 'Test Company',
        baseCurrencyCode: 'AED',
        baseCurrencyFractionDigits: 2,
        businessTimezone: 'Asia/Dubai',
      ),
      role: role,
    ),
    invoice: Invoice(
      id: 'invoice-1',
      companyId: 'company-1',
      customer: const InvoiceCustomerSnapshot(
        companyId: 'company-1',
        customerId: 'customer-1',
        name: 'Customer One',
      ),
      status: InvoiceStatus.draft,
      currency: currency,
      lines: [
        InvoiceTripLine(
          tripId: 'trip-1',
          tripNumber: 'TRP-2026-000001',
          loadingLocation: 'DUBAI',
          unloadingLocation: 'SHARJAH',
          amount: amount,
        ),
      ],
      totals: InvoiceTotals(
        subtotal: amount,
        discount: zero,
        taxableAmount: amount,
        taxRate: TaxRate.tryCreate(0)!,
        taxAmount: zero,
        grandTotal: amount,
      ),
      createdAt: DateTime.utc(2026, 8, 7),
      updatedAt: DateTime.utc(2026, 8, 7),
    ),
  );
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _pumpLocalized(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
