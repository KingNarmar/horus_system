import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:horus_system/features/reports/presentation/widgets/report_pdf_compact_preview.dart';
import 'package:horus_system/features/reports/presentation/widgets/report_pdf_preview_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  late Uint8List pdfBytes;

  setUpAll(() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Text('Report preview')));
    pdfBytes = await pdf.save();
  });

  testWidgets('mobile uses a full-screen preview with working zoom actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const Locale('en'), pdfBytes));

    expect(find.byType(ReportPdfCompactPreview), findsOneWidget);
    expect(find.byType(PdfPreviewCustom), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('150%'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(find.text('200%'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    expect(find.text('150%'), findsOneWidget);

    await tester.tap(find.byTooltip('Fit page'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('tablet uses the same accessible zoom controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(const Locale('ar'), pdfBytes));

    expect(find.byType(ReportPdfCompactPreview), findsOneWidget);
    expect(find.byTooltip('تكبير'), findsOneWidget);
    expect(find.byTooltip('تصغير'), findsOneWidget);
    expect(find.byTooltip('ملاءمة الصفحة'), findsOneWidget);
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

Widget _app(Locale locale, Uint8List bytes) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: ReportPdfPreviewDialog(bytes: bytes)),
);
