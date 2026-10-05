import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/operational_report.dart';
import 'package:grupo_sucuarana_app/report_attachment.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_pdf.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  test('gera PDF institucional válido e carrega anexos por injeção',
      () async {
    final loadedIds = <String>[];
    final bytes = await buildReportPdfBytes(
      _report(),
      attachmentBytesLoader: (attachment) async {
        loadedIds.add(attachment.id);
        return base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9WlOQAAAAASUVORK5CYII=',
        );
      },
    );

    expect(loadedIds, <String>['pdf-att-001']);
    expect(bytes.length, greaterThan(1500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('gera PDF mesmo quando arquivo de anexo não está disponível',
      () async {
    final bytes = await buildReportPdfBytes(
      _report(),
      attachmentBytesLoader: (_) async => null,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

Report _report() => Report(
      id: 'pdf-render-ficticio',
      identification: Identification(
        title: 'Relatório institucional fictício',
        date: DateTime.utc(2026, 10, 5),
        coordinator: 'Responsável fictício',
      ),
      searchTriage: SearchTriage.empty.copyWith(
        metadata: const TriageMetadata(
          formNumber: 'FORM-FICTICIO-001',
          factDate: '05/10/2026',
          factTime: '08:00',
          noticeDate: '05/10/2026',
          noticeTime: '08:30',
        ),
        person: const PersonIdentification(
          name: 'Pessoa fictícia',
          nickname: '',
          address: 'Endereço fictício',
          contacts: <String>[],
          additionalAddresses: <String>[],
          referenceContact: 'Contato fictício',
        ),
        previousActions: const PreviousActions(
          description: 'Procedimento fictício.',
        ),
      ),
      operation: const Operation(
        location: 'Área fictícia',
        start: '09:00',
        end: '13:00',
      ),
      operationalContent: const OperationalReportContent(
        generalInformation: OperationalGeneralInformation(
          externalReference: 'REF-FICTICIA',
          documentRg: '',
          documentCpf: '',
          phone: '',
          contactMadeBy: 'Contato fictício',
        ),
        occurrenceNarrative:
            'Descrição fictícia da ocorrência para teste do documento.',
        developmentNarrative:
            'Desenvolvimento fictício da atuação operacional.',
        teams: <OperationalTeam>[
          OperationalTeam(
            name: 'Equipe fictícia',
            members: <String>['Integrante fictício'],
          ),
        ],
        resources: <OperationalResource>[
          OperationalResource(
            description: 'Recurso fictício',
            purpose: 'Finalidade fictícia',
          ),
        ],
        conclusion: 'Conclusão fictícia.',
      ),
      attachmentItems: const <ReportAttachment>[
        ReportAttachment(
          id: 'pdf-att-001',
          localPath: '/local/ficticio/anexo.png',
          originalName: 'anexo.png',
          caption: 'Anexo fictício',
          managedLocalFile: true,
        ),
      ],
      createdAt: DateTime.utc(2026, 10, 5, 8),
      updatedAt: DateTime.utc(2026, 10, 5, 13),
      lifecycle: ReportLifecycle.readyForReview,
      lastEditedStep: 16,
      lastEditedSection: 'conclusionAndAttachments',
      syncStatus: SyncStatus.pending,
    );
