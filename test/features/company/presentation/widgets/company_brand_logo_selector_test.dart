import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/presentation/widgets/company_brand_logo_selector.dart';

void main() {
  testWidgets('logo selection is optional and can be replaced or removed',
      (tester) async {
    var selections = 0;
    var removals = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CompanyBrandLogoSelector(
          imageBytes: null,
          hasLogo: false,
          enabled: true,
          onChoose: () => selections++,
          onRemove: () => removals++,
        ),
      ),
    ));

    expect(find.text('Select logo'), findsOneWidget);
    expect(find.text('Remove logo'), findsNothing);
    await tester.tap(find.text('Select logo'));
    expect(selections, 1);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CompanyBrandLogoSelector(
          imageBytes: null,
          hasLogo: true,
          enabled: true,
          onChoose: () => selections++,
          onRemove: () => removals++,
        ),
      ),
    ));

    expect(find.text('Replace logo'), findsOneWidget);
    expect(find.text('Remove logo'), findsOneWidget);
    await tester.tap(find.text('Remove logo'));
    expect(removals, 1);
  });

  testWidgets('Arabic branding controls remain localized and disabled',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(
        body: CompanyBrandLogoSelector(
          imageBytes: null,
          hasLogo: true,
          enabled: false,
          onChoose: () {},
          onRemove: () {},
        ),
      ),
    ));

    expect(find.text('تغيير الشعار'), findsOneWidget);
    expect(find.text('إزالة الشعار'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'تغيير الشعار'),
      ).onPressed,
      isNull,
    );
  });
}
