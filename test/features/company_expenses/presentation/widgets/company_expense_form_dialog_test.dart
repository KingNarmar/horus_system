import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_category.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_form_lookups.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_link_option.dart';
import 'package:horus_system/features/company_expenses/presentation/widgets/company_expense_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'Trip dropdown constrains long labels without horizontal overflow',
    (tester) async {
      tester.view.physicalSize = const Size(520, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => CompanyExpenseFormDialog(
                          categories: const [_category],
                          formLookups: const CompanyExpenseFormLookups(
                            trips: [_tripOption],
                          ),
                          initialBusinessDate: _businessDate,
                          onSubmit: (_) async {},
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String?>);
      expect(dropdowns, findsNWidgets(4));

      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      expect(find.text(_tripLabel), findsOneWidget);

      final tripText = tester.widget<Text>(find.text(_tripLabel));
      expect(tripText.maxLines, 1);
      expect(tripText.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    },
  );
}

const _category = CompanyExpenseCategory(
  id: 'category-1',
  companyId: 'company-1',
  name: 'Vehicle maintenance',
  isActive: true,
);

const _tripOption = CompanyExpenseLinkOption(
  id: 'trip-1',
  label: _tripLabel,
);

const _tripLabel =
    'TRP-2026-000004 - Mina - DUBAI -> SHARJAH - additional long context';

const _businessDate = BusinessDate(year: 2026, month: 9, day: 22);
