import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:horus_system/features/invoices/data/services/invoice_pdf_route_cell.dart';

void main() {
  test('keeps the route arrow vector-based and travel order LTR', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: 'Route1',
      unloadingLocation: 'Dubai',
      unavailable: 'N/A',
    );

    final direction = cell as pw.Directionality;
    final content = direction.child as pw.RichText;
    final spans = (content.text as pw.TextSpan).children!;
    expect(direction.textDirection, pw.TextDirection.ltr);
    expect(content.textDirection, pw.TextDirection.ltr);
    expect(content.softWrap, isTrue);
    expect(spans, hasLength(5));
    final loading = (spans[0] as pw.WidgetSpan).child as pw.Text;
    final unloading = (spans[4] as pw.WidgetSpan).child as pw.Text;
    expect((loading.text as pw.TextSpan).text, 'Route1');
    expect((unloading.text as pw.TextSpan).text, 'Dubai');
    expect(loading.textDirection, pw.TextDirection.ltr);
    expect(unloading.textDirection, pw.TextDirection.ltr);
    expect((spans[2] as pw.WidgetSpan).child, isA<pw.CustomPaint>());
    expect(
      spans.whereType<pw.TextSpan>().any(
        (span) => span.text?.contains('→') ?? false,
      ),
      isFalse,
    );
  });

  test('shapes mixed Arabic/English locations without reversing the trip', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: '  جبل علي  ',
      unloadingLocation: '  Dubai Route 1  ',
      unavailable: 'غير متاح',
    );

    final content = (cell as pw.Directionality).child as pw.RichText;
    final spans = (content.text as pw.TextSpan).children!;
    final loading = (spans.first as pw.WidgetSpan).child as pw.Text;
    final unloading = (spans.last as pw.WidgetSpan).child as pw.Text;
    expect((loading.text as pw.TextSpan).text, 'جبل علي');
    expect(loading.textDirection, pw.TextDirection.rtl);
    expect((unloading.text as pw.TextSpan).text, 'Dubai Route 1');
    expect(unloading.textDirection, pw.TextDirection.ltr);
    expect((spans[2] as pw.WidgetSpan).child, isA<pw.CustomPaint>());
  });

  test('both Arabic route endpoints use RTL text shaping', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: 'ميناء جبل علي المنطقة الصناعية السادسة',
      unloadingLocation: 'منطقة دبي الجنوب للخدمات اللوجستية',
      unavailable: 'غير متاح',
    );

    final direction = cell as pw.Directionality;
    final content = direction.child as pw.RichText;
    final spans = (content.text as pw.TextSpan).children!;
    expect(direction.textDirection, pw.TextDirection.ltr);
    expect(content.textDirection, pw.TextDirection.ltr);
    final loading = (spans.first as pw.WidgetSpan).child as pw.Text;
    final unloading = (spans.last as pw.WidgetSpan).child as pw.Text;
    expect(loading.textDirection, pw.TextDirection.rtl);
    expect(unloading.textDirection, pw.TextDirection.rtl);
    expect(loading.softWrap, isTrue);
    expect(unloading.softWrap, isTrue);
    expect(
      (loading.text as pw.TextSpan).text,
      'ميناء جبل علي المنطقة الصناعية السادسة',
    );
    expect(
      (unloading.text as pw.TextSpan).text,
      'منطقة دبي الجنوب للخدمات اللوجستية',
    );
  });

  test('Arabic fallback preserves RTL when both route ends are absent', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: ' ',
      unloadingLocation: null,
      unavailable: 'غير متاح',
    );
    final content = (cell as pw.Directionality).child as pw.Text;
    expect((content.text as pw.TextSpan).text, 'غير متاح');
    expect(content.textDirection, pw.TextDirection.rtl);
  });

  test('one-sided Latin route remains LTR without an arrow', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: 'Jebel Ali',
      unloadingLocation: null,
      unavailable: 'N/A',
    );
    final content = (cell as pw.Directionality).child as pw.Text;
    expect((content.text as pw.TextSpan).text, 'Jebel Ali');
    expect(content.textDirection, pw.TextDirection.ltr);
  });

  test('one-sided Arabic route remains RTL without an arrow', () {
    final cell = InvoicePdfRouteCell.build(
      loadingLocation: null,
      unloadingLocation: 'ميناء جدة الإسلامي',
      unavailable: 'غير متاح',
    );
    final content = (cell as pw.Directionality).child as pw.Text;
    expect((content.text as pw.TextSpan).text, 'ميناء جدة الإسلامي');
    expect(content.textDirection, pw.TextDirection.rtl);
  });

}
