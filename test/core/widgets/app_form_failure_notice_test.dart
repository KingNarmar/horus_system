import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/constants/app_icons.dart';
import 'package:horus_system/core/widgets/app_form_failure_notice.dart';

void main() {
  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets('long form error wraps without overflow in $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: direction,
              child: Center(
                child: SizedBox(
                  width: 280,
                  child: AppFormFailureNotice(
                    message:
                        'A capacity limit has been reached. '
                        'An existing record must be deactivated before '
                        'another record can be added or reactivated.',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppFormFailureNotice), findsOneWidget);
      expect(find.byIcon(AppIcons.bootstrapFailure), findsOneWidget);
      final notice = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppFormFailureNotice),
          matching: find.byType(Container),
        ).first,
      );
      final colors = Theme.of(
        tester.element(find.byType(AppFormFailureNotice)),
      ).colorScheme;
      expect((notice.decoration as BoxDecoration).color, colors.inverseSurface);
      expect(tester.takeException(), isNull);
    });
  }
}
