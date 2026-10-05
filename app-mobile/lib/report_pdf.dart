import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'pdf/report_pdf_document.dart';
import 'pdf/report_pdf_plan.dart';
import 'report_model.dart';

Future<Uint8List> buildReportPdfBytes(
  Report report, {
  ReportAttachmentBytesLoader attachmentBytesLoader =
      loadLocalReportAttachment,
}) =>
    buildInstitutionalReportPdf(
      ReportPdfPlan.fromReport(report),
      attachmentBytesLoader: attachmentBytesLoader,
    );

Future<void> exportReportPdf(Report report) async {
  final bytes = await buildReportPdfBytes(report);
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'relatorio-${report.id}.pdf',
  );
}
