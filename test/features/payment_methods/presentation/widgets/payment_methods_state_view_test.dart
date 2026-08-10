import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_status_filter.dart';
import 'package:horus_system/features/payment_methods/presentation/cubit/payment_methods_state.dart';
import 'package:horus_system/features/payment_methods/presentation/widgets/payment_methods_state_view.dart';

void main() {
  testWidgets('status filters switch between active inactive and all methods', (
    tester,
  ) async {
    var filter = PaymentMethodStatusFilter.active;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 400,
                child: PaymentMethodsStateView(
                  state: PaymentMethodsLoaded(
                    currentCompanyContext: _context(),
                    allMethods: const [
                      PaymentMethod(
                        id: 'cash',
                        companyId: 'company-1',
                        name: 'Cash',
                        isActive: true,
                      ),
                      PaymentMethod(
                        id: 'cheque',
                        companyId: 'company-1',
                        name: 'Cheque',
                        isActive: false,
                      ),
                    ],
                    canManagePaymentMethods: true,
                    statusFilter: filter,
                  ),
                  onRetry: () {},
                  onStatusFilterChanged: (value) {
                    setState(() => filter = value);
                  },
                  onEdit: (_) {},
                  onDeactivate: (_) {},
                  onReactivate: (_) {},
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Cheque'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Inactive'));
    await tester.pump();
    expect(find.text('Cash'), findsNothing);
    expect(find.text('Cheque'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pump();
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Cheque'), findsOneWidget);
  });
}

CurrentCompanyContext _context() {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: CompanyRole.accountant,
  );
}
