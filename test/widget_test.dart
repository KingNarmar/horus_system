import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/app.dart';

void main() {
  testWidgets('H.O.R.U.S launch page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const HorusApp());

    expect(find.text('H.O.R.U.S System'), findsOneWidget);
    expect(find.text('Heavy Operations & Route Unified System'), findsOneWidget);
  });
}
