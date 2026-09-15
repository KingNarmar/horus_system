import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_status_filter.dart';
import 'package:horus_system/features/expense_types/presentation/cubit/expense_types_state.dart';
import 'package:horus_system/features/expense_types/presentation/widgets/expense_types_state_view.dart';

void main() {
  testWidgets('status filters switch between active inactive and all types', (
    tester,
  ) async {
    var filter = ExpenseTypeStatusFilter.active;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 400,
                child: ExpenseTypesStateView(
                  state: ExpenseTypesLoaded(
                    allTypes: const [
                      ExpenseType(
                        id: 'fuel',
                        companyId: 'company-1',
                        name: 'Fuel',
                        isActive: true,
                      ),
                      ExpenseType(
                        id: 'road-fees',
                        companyId: 'company-1',
                        name: 'Road fees',
                        isActive: false,
                      ),
                    ],
                    statusFilter: filter,
                  ),
                  onRetry: () {},
                  onStatusFilterChanged: (value) {
                    setState(() => filter = value);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Road fees'), findsNothing);
    expect(find.byType(IconButton), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Inactive'));
    await tester.pump();
    expect(find.text('Fuel'), findsNothing);
    expect(find.text('Road fees'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pump();
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Road fees'), findsOneWidget);
  });
}
