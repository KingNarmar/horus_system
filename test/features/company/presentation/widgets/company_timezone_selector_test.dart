import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:horus_system/features/company/presentation/helpers/company_timezone_display_option.dart';
import 'package:horus_system/features/company/presentation/widgets/company_timezone_selector.dart';

void main() {
  testWidgets(
    'Arabic selector localizes names and searches Arabic English and IANA',
    (tester) async {
      final options = [
        CompanyTimezone.tryParse('Asia/Dubai')!,
        CompanyTimezone.tryParse('Europe/London')!,
      ];
      final arabicLondon = CompanyTimezoneDisplayResolver.resolve(
        options.last,
        const Locale('ar'),
      );
      String? selectedValue = 'Asia/Dubai';

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CompanyTimezoneSelector(
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

      await tester.tap(find.byType(CompanyTimezoneSelector));
      await tester.pumpAndSettle();

      expect(find.text('اختيار المنطقة الزمنية'), findsOneWidget);

      final searchField = find.byType(TextField);
      final londonResult = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(arabicLondon.localizedName),
      );

      await tester.enterText(searchField, 'London');
      await tester.pump();
      expect(londonResult, findsOneWidget);
      expect(find.text('Europe/London'), findsOneWidget);

      await tester.enterText(searchField, arabicLondon.localizedName);
      await tester.pump();
      expect(londonResult, findsOneWidget);

      await tester.enterText(searchField, 'Europe/London');
      await tester.pump();
      expect(londonResult, findsOneWidget);

      await tester.tap(londonResult);
      await tester.pumpAndSettle();

      expect(selectedValue, 'Europe/London');
      expect(find.text(arabicLondon.localizedName), findsOneWidget);
    },
  );
}
