import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_pdf_preview_page.dart';

void main() {
  testWidgets('gera uma vez e compartilha e imprime os mesmos bytes',
      (tester) async {
    var buildCalls = 0;
    Uint8List? sharedBytes;
    Uint8List? printedBytes;
    String? sharedFilename;
    String? printedFilename;

    final bytes = Uint8List.fromList(<int>[37, 80, 68, 70, 45]);

    await tester.pumpWidget(
      MaterialApp(
        home: ReportPdfPreviewPage(
          report: _report(),
          bytesBuilder: (_) async {
            buildCalls++;
            return bytes;
          },
          previewBuilder: (_, value) => Text(
            'preview-${value.length}',
            key: const ValueKey('fake-preview'),
          ),
          shareAction: (
            value, {
            required String filename,
          }) async {
            sharedBytes = value;
            sharedFilename = filename;
          },
          printAction: (
            value, {
            required String filename,
          }) async {
            printedBytes = value;
            printedFilename = filename;
            return true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(buildCalls, 1);
    expect(find.byKey(const ValueKey('fake-preview')), findsOneWidget);
    expect(find.text('preview-5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('share-pdf')));
    await tester.pumpAndSettle();

    expect(sharedBytes, same(bytes));
    expect(sharedFilename, 'relatorio-preview-ficticio.pdf');

    await tester.tap(find.byKey(const ValueKey('print-pdf')));
    await tester.pumpAndSettle();

    expect(printedBytes, same(bytes));
    expect(printedFilename, 'relatorio-preview-ficticio.pdf');
    expect(buildCalls, 1);
  });

  testWidgets('erro de geração permite tentar novamente', (tester) async {
    var buildCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReportPdfPreviewPage(
          report: _report(),
          bytesBuilder: (_) async {
            buildCalls++;
            if (buildCalls == 1) {
              throw StateError('falha fictícia');
            }
            return Uint8List.fromList(<int>[37, 80, 68, 70]);
          },
          previewBuilder: (_, __) => const Text(
            'preview recuperado',
            key: ValueKey('recovered-preview'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pdf-preview-error')), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(buildCalls, 2);
    expect(find.byKey(const ValueKey('recovered-preview')), findsOneWidget);
  });

  testWidgets('falha de impressão mantém preview e informa o usuário',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReportPdfPreviewPage(
          report: _report(),
          bytesBuilder: (_) async =>
              Uint8List.fromList(<int>[37, 80, 68, 70]),
          previewBuilder: (_, __) => const Text('preview fictício'),
          printAction: (
            _, {
            required String filename,
          }) async =>
              false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('print-pdf')));
    await tester.pump();

    expect(
      find.text('A impressão foi cancelada ou não pôde ser iniciada.'),
      findsOneWidget,
    );
    expect(find.text('preview fictício'), findsOneWidget);
  });
}

Report _report() {
  final timestamp = DateTime.utc(2026, 10, 5, 18);

  return Report(
    id: 'preview-ficticio',
    identification: Identification(
      title: 'Relatório fictício',
      date: timestamp,
      coordinator: 'Equipe fictícia',
    ),
    missing: const MissingPerson(
      name: 'Pessoa fictícia',
      lastSeen: 'Local fictício',
      contact: 'Contato fictício',
    ),
    operation: const Operation(
      location: 'Cidade fictícia',
      start: '08:00',
      end: '12:00',
    ),
    physicalDescription: 'Descrição fictícia.',
    clothing: 'Vestimenta fictícia.',
    health: 'Sem dados reais.',
    procedures: 'Procedimento fictício.',
    teams: const <String>['Equipe fictícia'],
    resources: const <String>['Recurso fictício'],
    conclusion: 'Conclusão fictícia.',
    attachments: const <String>[],
    createdAt: timestamp.subtract(const Duration(hours: 1)),
    updatedAt: timestamp,
    lifecycle: ReportLifecycle.readyForReview,
    lastEditedStep: 16,
    lastEditedSection: 'conclusionAndAttachments',
    syncStatus: SyncStatus.pending,
  );
}
