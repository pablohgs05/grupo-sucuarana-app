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
    'Desaparecido': [
      'Nome/referência: ${report.missing.name}',
      'Último avistamento: ${report.missing.lastSeen}',
      'Contato de referência: ${report.missing.contact}',
    ],
    'Operação': [
      'Local: ${report.operation.location}',
      'Início: ${report.operation.start}',
      'Término: ${report.operation.end}',
    ],
    'Descrição física': [report.physicalDescription],
    'Vestimentas': [report.clothing],
    'Saúde': [report.health],
    'Procedimentos': [report.procedures],
    'Equipes': [report.teams.join(', ')],
    'Recursos': [report.resources.join(', ')],
    'Conclusão': [report.conclusion],
    'Anexos': [report.attachments.isEmpty ? 'Nenhum anexo' : report.attachments.join('\n')],
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
