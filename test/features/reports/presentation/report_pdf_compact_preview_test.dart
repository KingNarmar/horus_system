import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:horus_system/features/reports/presentation/widgets/report_pdf_compact_preview.dart';
import 'package:horus_system/features/reports/presentation/widgets/report_pdf_page_viewer.dart';
import 'package:horus_system/features/reports/presentation/widgets/report_pdf_preview_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  late Uint8List pdfBytes;

  setUpAll(() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Text('Report preview')));
    pdfBytes = await pdf.save();
  });

  testWidgets('mobile retains a full-screen custom PDF preview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const Locale('en'), pdfBytes));

    expect(find.byType(ReportPdfCompactPreview), findsOneWidget);
    expect(find.byType(PdfPreviewCustom), findsOneWidget);
  });

  testWidgets('short landscape page pinch zooms out to 100 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_viewerApp([_page(width: 842, height: 595)]));

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      tester.getSize(find.byWidget(viewer.child!)).height,
      greaterThanOrEqualTo(tester.getSize(find.byType(InteractiveViewer)).height),
    );
    expect(_scale(tester), 1.0);

    await _pinch(tester, startRadius: 30, endRadius: 90);
    expect(_scale(tester), greaterThan(1.1));
    await _pinch(tester, startRadius: 90, endRadius: 12);
    expect(_scale(tester), closeTo(1.0, 0.01));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('portrait page also recovers minimum zoom after a pinch', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_viewerApp([_page(width: 595, height: 842)]));
    await _pinch(tester, startRadius: 30, endRadius: 90);
    expect(_scale(tester), greaterThan(1.1));
    await _pinch(tester, startRadius: 90, endRadius: 12);
    expect(_scale(tester), closeTo(1.0, 0.01));
  });

  testWidgets('buttons keep the focal point and fit after a touch gesture', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_viewerApp([_page(width: 842, height: 595)]));
    await _pinch(tester, startRadius: 30, endRadius: 65);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final controller = viewer.transformationController!;
    final center = tester.getSize(find.byType(InteractiveViewer)).center(
      Offset.zero,
    );
    final before = controller.toScene(center);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect((controller.toScene(center) - before).distance, lessThan(0.5));

    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fit page'));
    await tester.pump();
    expect(_scale(tester), 1.0);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('horizontal pan reaches both landscape page edges', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_viewerApp([_page(width: 842, height: 595)]));
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();

    final viewport = tester.getRect(find.byType(InteractiveViewer));
    final page = find.byType(AspectRatio).first;
    await tester.timedDrag(
      find.byType(InteractiveViewer),
      const Offset(900, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    final left = tester.getRect(page);
    expect(left.left, greaterThanOrEqualTo(viewport.left));
    expect(left.left, lessThan(viewport.left + 40));

    await tester.timedDrag(
      find.byType(InteractiveViewer),
      const Offset(-900, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    final right = tester.getRect(page);
    expect(right.right, lessThanOrEqualTo(viewport.right));
    expect(right.right, greaterThan(viewport.right - 40));
  });

  testWidgets('vertical pan reaches first and last pages in a long PDF', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _viewerApp([
        _page(width: 595, height: 842),
        _page(width: 595, height: 842),
        _page(width: 595, height: 842),
      ]),
    );
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();

    final viewport = tester.getRect(find.byType(InteractiveViewer));
    await tester.timedDrag(
      find.byType(InteractiveViewer),
      const Offset(0, 5000),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    final firstPage = tester.getRect(find.byType(AspectRatio).first);
    expect(firstPage.top, greaterThanOrEqualTo(viewport.top));
    expect(firstPage.top, lessThan(viewport.top + 40));

    await tester.timedDrag(
      find.byType(InteractiveViewer),
      const Offset(0, -5000),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    final lastPage = tester.getRect(find.byType(AspectRatio).last);
    expect(lastPage.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(lastPage.bottom, greaterThan(viewport.bottom - 40));
  });

  testWidgets('tablet displays localized zoom controls in Arabic', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _viewerApp([_page(width: 842, height: 595)], locale: const Locale('ar')),
    );

    expect(find.byTooltip('تكبير'), findsOneWidget);
    expect(find.byTooltip('تصغير'), findsOneWidget);
    expect(find.byTooltip('ملاءمة الصفحة'), findsOneWidget);
    await tester.tap(find.byTooltip('تكبير'));
    await tester.pump();
    expect(find.text('150%'), findsOneWidget);
    await tester.tap(find.byTooltip('ملاءمة الصفحة'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('desktop retains the existing dialog-based PdfPreview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const Locale('en'), pdfBytes));

    expect(find.byType(ReportPdfCompactPreview), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(PdfPreview), findsOneWidget);
  });
}

// Rasterized page dimensions are controlled here, without a native PDF plugin.
PdfPreviewPageData _page({required int width, required int height}) =>
    PdfPreviewPageData(image: MemoryImage(_pixel), width: width, height: height);

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGP8+vXrfwYGBgYmBigAADwYA+IEIyRGAAAAAElFTkSuQmCC',
);

Widget _app(Locale locale, Uint8List bytes) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ReportPdfPreviewDialog(bytes: bytes)),
);

Widget _viewerApp(
  List<PdfPreviewPageData> pages, {
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ReportPdfPageViewer(pages: pages)),
);

double _scale(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

Future<void> _pinch(
  WidgetTester tester, {
  required double startRadius,
  required double endRadius,
}) async {
  final center = tester.getCenter(find.byType(InteractiveViewer));
  final first = await tester.createGesture(pointer: 1);
  final second = await tester.createGesture(pointer: 2);
  await first.down(center.translate(-startRadius, 0));
  await second.down(center.translate(startRadius, 0));
  await tester.pump();
  await first.moveTo(center.translate(-endRadius, 0));
  await second.moveTo(center.translate(endRadius, 0));
  await tester.pump();
  await first.up();
  await second.up();
  await tester.pumpAndSettle();
}
