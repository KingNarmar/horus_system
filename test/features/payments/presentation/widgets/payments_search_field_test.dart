import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/payments/presentation/widgets/payments_search_field.dart';

void main() {
  testWidgets('restores search text when reconnect recreates the field', (
    tester,
  ) async {
    Widget app(String? query) => MaterialApp(
      home: Scaffold(
        body: query == null
            ? const CircularProgressIndicator()
            : PaymentsSearchField(
                query: query,
                hintText: 'Search',
                onChanged: (_) {},
              ),
      ),
    );

    await tester.pumpWidget(app('invoice-123'));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'invoice-123');

    await tester.pumpWidget(app(null));
    expect(find.byType(TextField), findsNothing);

    await tester.pumpWidget(app('invoice-123'));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'invoice-123');
  });

  testWidgets('forwards typed intent and synchronizes externally changed query', (
    tester,
  ) async {
    final changes = <String>[];
    Widget app(String query) => MaterialApp(
      home: Scaffold(
        body: PaymentsSearchField(
          query: query,
          hintText: 'Search',
          onChanged: changes.add,
        ),
      ),
    );

    await tester.pumpWidget(app('previous'));
    await tester.enterText(find.byType(TextField), 'reference');
    expect(changes, ['reference']);

    await tester.pumpWidget(app('reference'));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'reference');

    await tester.pumpWidget(app('updated'));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'updated');
  });
}
