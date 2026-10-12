import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'pdf/report_pdf_document.dart';
import 'pdf/report_pdf_plan.dart';
import 'report_model.dart';

String reportPdfFilename(Report report) => 'relatorio-${report.id}.pdf';

Future<Uint8List> buildReportPdfBytes(
  Report report, {
  ReportAttachmentBytesLoader attachmentBytesLoader =
      loadLocalReportAttachment,
}) =>
    buildInstitutionalReportPdf(
      ReportPdfPlan.fromReport(report),
      attachmentBytesLoader: attachmentBytesLoader,
    );

Future<void> shareReportPdfBytes(
  Uint8List bytes, {
  required String filename,
}) =>
    Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );

Future<bool> printReportPdfBytes(
  Uint8List bytes, {
  required String filename,
}) =>
    Printing.layoutPdf(
      name: filename,
      onLayout: (PdfPageFormat _) async => bytes,
    );

Future<void> exportReportPdf(Report report) async {
  final bytes = await buildReportPdfBytes(report);
  await shareReportPdfBytes(
    bytes,
    filename: reportPdfFilename(report),
  );
}
