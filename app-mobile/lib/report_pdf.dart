import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'report_model.dart';

Future<void> exportReportPdf(Report report) async {
  final document = pw.Document();
  final sections = <String, List<String>>{
    'Identificação': [
      'Título: ${report.identification.title}',
      'Data: ${_date(report.identification.date)}',
      'Coordenação: ${report.identification.coordinator}',
    ],
    'Informações gerais': [
      'Nome/referência: ${report.missing.name}',
      'Endereço: ${report.searchTriage.person.address}',
      'RG: ${report.operationalContent.generalInformation.documentRg}',
      'CPF: ${report.operationalContent.generalInformation.documentCpf}',
      'Telefone: ${report.operationalContent.generalInformation.phone}',
      'Contato feito por: '
          '${report.operationalContent.generalInformation.contactMadeBy}',
      'Referência externa: '
          '${report.operationalContent.generalInformation.externalReference}',
    ],
    'Descrição da ocorrência': [
      report.operationalContent.occurrenceNarrative,
    ],
    'Operação': [
      'Local: ${report.operation.location}',
      'Início: ${report.operation.start}',
      'Término: ${report.operation.end}',
    ],
    'Desenvolvimento do emprego da equipe': [
      report.operationalContent.developmentNarrative,
    ],
    'Equipes': [report.teams.join('\n')],
    'Recursos utilizados': [report.resources.join('\n')],
    'Conclusão': [report.conclusion],
    'Anexos': [
      report.attachmentItems.isEmpty
          ? 'Nenhum anexo'
          : report.attachmentItems.map(_attachmentLabel).join('\n'),
    ],
  };
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('Relatório de operação')),
        ...sections.entries.expand(
          (entry) => [
            pw.Header(level: 1, child: pw.Text(entry.key)),
            pw.Text(entry.value.join('\n')),
            pw.SizedBox(height: 10),
          ],
        ),
      ],
    ),
  );
  await Printing.sharePdf(bytes: await document.save(), filename: 'relatorio-${report.id}.pdf');
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';


String _attachmentLabel(dynamic attachment) {
  final name = attachment.originalName as String;
  final caption = attachment.caption as String;
  if (caption.trim().isEmpty) return name;
  return '$name — ${caption.trim()}';
}
