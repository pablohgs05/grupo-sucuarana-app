import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../report_attachment.dart';
import 'report_pdf_plan.dart';

typedef ReportAttachmentBytesLoader = Future<Uint8List?> Function(
  ReportAttachment attachment,
);

Future<Uint8List?> loadLocalReportAttachment(
  ReportAttachment attachment,
) async {
  if (attachment.localPath.trim().isEmpty) return null;

  try {
    final file = File(attachment.localPath);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<Uint8List> buildInstitutionalReportPdf(
  ReportPdfPlan plan, {
  ReportAttachmentBytesLoader attachmentBytesLoader =
      loadLocalReportAttachment,
}) async {
  final attachmentBytes = <String, Uint8List?>{};
  for (final attachment in plan.attachments) {
    attachmentBytes[attachment.id] =
        await attachmentBytesLoader(attachment);
  }

  final document = pw.Document();

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 38),
      build: (_) => _cover(plan),
    ),
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 88, 42, 56),
      maxPages: 100,
      header: (context) => _institutionalHeader(plan),
      footer: (context) => _institutionalFooter(plan, context),
      build: (_) => <pw.Widget>[
        _tableOfContents(),
        pw.NewPage(),
        _sectionHeader('1. Informações Gerais'),
        _fieldsTable(plan.generalInformation),
        pw.SizedBox(height: 12),
        _sectionHeader('2. Descrição da Ocorrência'),
        _paragraph(plan.occurrenceNarrative),
        pw.SizedBox(height: 8),
        _subsectionTitle('Dados operacionais'),
        _fieldsTable(plan.operationInformation),
        pw.SizedBox(height: 12),
        _sectionHeader('3. Desenvolvimento do emprego da equipe'),
        _paragraph(plan.developmentNarrative),
        if (plan.teams.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _subsectionTitle('Equipes operacionais'),
          _teamsTable(plan.teams),
        ],
        pw.SizedBox(height: 12),
        _sectionHeader('4. Recursos Utilizados'),
        _resources(plan.resources),
        pw.SizedBox(height: 12),
        _sectionHeader('5. Conclusão'),
        _paragraph(plan.conclusion),
        pw.SizedBox(height: 12),
        _sectionHeader('6. Anexo'),
        pw.NewPage(),
        _annexHeading(
          1,
          'Formulário de buscas utilizado na triagem das informações.',
        ),
        pw.SizedBox(height: 8),
        ...plan.triageGroups.expand(
          (group) => <pw.Widget>[
            _triageGroup(group),
            pw.SizedBox(height: 8),
          ],
        ),
        ...plan.attachments.asMap().entries.expand((entry) {
          final annexNumber = entry.key + 2;
          final attachment = entry.value;
          final title = attachment.caption.trim().isEmpty
              ? attachment.originalName
              : attachment.caption.trim();
          return <pw.Widget>[
            pw.NewPage(),
            _annexHeading(annexNumber, title),
            pw.SizedBox(height: 12),
            _attachmentContent(
              attachment,
              attachmentBytes[attachment.id],
            ),
          ];
        }),
      ],
    ),
  );

  return document.save();
}

pw.Widget _cover(ReportPdfPlan plan) {
  final formLine = plan.formNumber == 'Não informado'
      ? null
      : 'Formulário de buscas - nº ${plan.formNumber}';
  final referenceLine = plan.externalReference == 'Não informado'
      ? null
      : 'Referência: ${plan.externalReference}';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        'Nome: ${plan.coordinator}',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 28),
      pw.Text(
        plan.title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.red700,
        ),
      ),
      if (referenceLine != null) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          referenceLine,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
      pw.Spacer(),
      pw.Center(
        child: pw.Container(
          width: 180,
          height: 180,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColors.green800,
              width: 3,
            ),
            borderRadius: const pw.BorderRadius.all(
              pw.Radius.circular(90),
            ),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'G.S.',
                style: pw.TextStyle(
                  fontSize: 38,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'GRUPO SUÇUARANA',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Spacer(),
      pw.Text(
        'Relatório de ocorrência',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.red700,
        ),
      ),
      if (formLine != null) ...[
        pw.SizedBox(height: 5),
        pw.Text(
          formLine,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red700,
          ),
        ),
      ],
      pw.SizedBox(height: 26),
      pw.Text(
        plan.branding.organization,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        plan.location,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        plan.monthYearLabel,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
    ],
  );
}

pw.Widget _tableOfContents() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Sumário',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.TableOfContent(),
      ],
    );

pw.Widget _institutionalHeader(ReportPdfPlan plan) => pw.Column(
      children: [
        pw.Text(
          plan.branding.organization,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          '“${plan.branding.tagline}”',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 8,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.orange800,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          plan.branding.registrationLine,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'E-MAIL: ${plan.branding.email}',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7),
        ),
        pw.Text(
          'SITE: ${plan.branding.siteLine}',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 7),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: PdfColors.grey400, height: 1),
      ],
    );

pw.Widget _institutionalFooter(
  ReportPdfPlan plan,
  pw.Context context,
) {
  final page = context.pageNumber > 1
      ? context.pageNumber - 1
      : context.pageNumber;

  return pw.Column(
    children: [
      pw.Divider(color: PdfColors.grey300, height: 1),
      pw.SizedBox(height: 3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'E-MAIL: ${plan.branding.email}\n'
              'SITE: ${plan.branding.siteLine}',
              style: const pw.TextStyle(
                fontSize: 6.5,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Text(
            '$page',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _sectionHeader(String title) => pw.Header(
      level: 0,
      text: title,
      margin: const pw.EdgeInsets.only(bottom: 8),
      textStyle: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    );

pw.Widget _subsectionTitle(String title) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 7,
      ),
      color: PdfColors.grey300,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

pw.Widget _fieldsTable(List<ReportPdfField> fields) => pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey500,
        width: 0.5,
      ),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(135),
        1: pw.FlexColumnWidth(),
      },
      children: fields
          .map(
            (field) => pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    field.label,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    field.value,
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
              ],
            ),
          )
          .toList(growable: false),
    );

pw.Widget _paragraph(String value) => pw.Paragraph(
      text: value,
      textAlign: pw.TextAlign.justify,
      style: const pw.TextStyle(
        fontSize: 10,
        lineSpacing: 2,
      ),
      margin: const pw.EdgeInsets.only(bottom: 6),
    );

pw.Widget _teamsTable(List<ReportPdfTeam> teams) => pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey500,
        width: 0.5,
      ),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(120),
        1: pw.FlexColumnWidth(),
      },
      children: teams
          .map(
            (team) => pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    team.name,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    team.members.isEmpty
                        ? 'Não informado'
                        : team.members.join(', '),
                    style: const pw.TextStyle(fontSize: 8.5),
                  ),
                ),
              ],
            ),
          )
          .toList(growable: false),
    );

pw.Widget _resources(List<ReportPdfResource> resources) {
  if (resources.isEmpty) {
    return pw.Text(
      'Não informado',
      style: const pw.TextStyle(fontSize: 10),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: resources.map((resource) {
      final description = resource.description == 'Não informado'
          ? ''
          : resource.description;
      final purpose = resource.purpose == 'Não informado'
          ? ''
          : resource.purpose;
      final text = purpose.isEmpty
          ? description
          : description.isEmpty
              ? purpose
              : '$description ($purpose)';

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(
          '- ${text.isEmpty ? 'Não informado' : text}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }).toList(growable: false),
  );
}

pw.Widget _triageGroup(ReportPdfGroup group) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _subsectionTitle(group.title),
        _fieldsTable(group.fields),
      ],
    );

pw.Widget _annexHeading(int number, String title) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 8,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey600,
          width: 0.7,
        ),
      ),
      child: pw.Text(
        'Anexo ${number.toString().padLeft(2, '0')} - $title',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );

pw.Widget _attachmentContent(
  ReportAttachment attachment,
  Uint8List? bytes,
) {
  if (bytes == null || bytes.isEmpty) {
    return pw.Container(
      height: 320,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            attachment.originalName,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Arquivo de imagem indisponível neste dispositivo.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(
        height: 570,
        alignment: pw.Alignment.center,
        child: pw.Image(
          pw.MemoryImage(bytes),
          fit: pw.BoxFit.contain,
        ),
      ),
      if (attachment.caption.trim().isNotEmpty) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          attachment.caption.trim(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
      pw.SizedBox(height: 4),
      pw.Text(
        attachment.originalName,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(
          fontSize: 7,
          color: PdfColors.grey600,
        ),
      ),
    ],
  );
}
