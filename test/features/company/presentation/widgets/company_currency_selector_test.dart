import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/presentation/helpers/company_currency_display_option.dart';
import 'package:horus_system/features/company/presentation/widgets/company_currency_selector.dart';

void main() {
  testWidgets('unselected currency selector shows one label and one hint', (
    tester,
  ) async {
    final options = CompanyCurrencyDisplayResolver.resolveAll(
      const Locale('en'),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: CompanyCurrencySelector(
            options: options,
            selectedValue: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Base currency'), findsOneWidget);
    expect(find.text('Select a currency'), findsOneWidget);
  });

  testWidgets(
    'Arabic currency selector searches by code English name and Arabic name',
    (tester) async {
      final options = CompanyCurrencyDisplayResolver.resolveAll(
        const Locale('ar'),
      );
      final aed = options.singleWhere((option) => option.value == 'AED');
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CompanyCurrencySelector(
                  options: options,
                  selectedValue: selectedValue,
                  onChanged: (value) {
                    setState(() => selectedValue = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CompanyCurrencySelector));
      await tester.pumpAndSettle();

      expect(find.text('اختيار العملة الأساسية'), findsOneWidget);

      final searchField = find.byType(TextField);
      Finder aedResult() => find.descendant(
        of: find.byType(ListTile),
        matching: find.text(aed.localizedName),
      );

      await tester.enterText(searchField, 'AED');
      await tester.pump();
      expect(aedResult(), findsOneWidget);

      await tester.enterText(searchField, aed.englishName);
      await tester.pump();
      expect(aedResult(), findsOneWidget);

      await tester.enterText(searchField, aed.arabicName);
      await tester.pump();
      expect(aedResult(), findsOneWidget);

      await tester.tap(aedResult());
      await tester.pumpAndSettle();

      expect(selectedValue, 'AED');
      expect(find.text(aed.localizedName), findsOneWidget);
      expect(find.text('AED'), findsOneWidget);
    },
  );
}
