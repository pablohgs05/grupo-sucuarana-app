import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/operational_report.dart';
import 'package:grupo_sucuarana_app/report_attachment.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_pdf.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF institucional válido e carrega anexos por injeção',
      () async {
    final loadedIds = <String>[];
    final bytes = await buildReportPdfBytes(
      _report(),
      attachmentBytesLoader: (attachment) async {
        loadedIds.add(attachment.id);
        return base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4//8/AAX+Av4N70a4AAAAAElFTkSuQmCC',
        );
      },
    );

    expect(loadedIds, <String>['pdf-att-001']);
    expect(bytes.length, greaterThan(1500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('gera sumário e mantém múltiplos anexos em páginas válidas',
      () async {
    final original = _report();
    final report = original.copyWith(
      operationalContent: original.operationalContent.copyWith(
        occurrenceNarrative: List.filled(
          16,
          'Narrativa fictícia extensa para exercitar a paginação do relatório. '
          'PONTUACAO — SETA → EMOJI 👽: todos caracteres do teste devem ser legíveis.',
        ).join(' '),
        developmentNarrative: List.filled(
          8,
          'Atividade fictícia documentada para teste de paginação.',
        ).join(' '),
      ),
      attachmentItems: <ReportAttachment>[
        const ReportAttachment(
          id: 'pdf-att-001',
          localPath: '/local/ficticio/imagem-01.png',
          originalName: 'imagem-ficticia-01.png',
          caption: 'Legenda fictícia da primeira fotografia.',
          managedLocalFile: true,
        ),
        ReportAttachment(
          id: 'pdf-att-002',
          localPath: '/local/ficticio/imagem-02.png',
          originalName: 'imagem-ficticia-02.png',
          caption: List.filled(
            5,
            'Legenda fictícia mais longa para testar a apresentação.',
          ).join(' '),
          managedLocalFile: true,
        ),
      ],
    );

    final loadedIds = <String>[];
    final bytes = await buildReportPdfBytes(
      report,
      attachmentBytesLoader: (attachment) async {
        loadedIds.add(attachment.id);
        return base64Decode(
          attachment.id == 'pdf-att-001'
              ? _fictitiousLandscapePng
              : _fictitiousPortraitPng,
        );
      },
    );

    // PDF page-level checks run in CI with pdftotext. Keep normal widget
    // tests side-effect-free unless the visual fixture is explicitly requested.
    final fixturePath = Platform.environment['PDF_LAYOUT_OUTPUT'];
    if (fixturePath != null && fixturePath.isNotEmpty) {
      final file = File(fixturePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    expect(loadedIds, <String>['pdf-att-001', 'pdf-att-002']);
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

// Generated geometric PNG fixtures: no real photos or operational records.
const _fictitiousLandscapePng =
    'iVBORw0KGgoAAAANSUhEUgAAAFAAAAAyCAIAAABET8urAAABz0lEQVR42t3aL1LDQBTH8Q3zFAYVu7kBAl2D4RDBcIKaXiOYngDTS2BiqhHcYDUqpjaIDSH/u919+/btRnSgw3T4zPc3mSaTTFalOpyK91eR/HE8i/0ua9u2fydZ9vHc/5jJqhRCqMMpWXOv3e/+wUNzOuxBWK0dgSfs6M3jsNNJL5pjZS+F3QJHzN6kXgF/P30KIR6ef/SvTZ0zxz6+3Xf/+cele+frZf5nsP0pTZ1rs37lye6pQ+3aAVc/TiN5sm+imoIX2RzM8w1jglkt3CKsJZhDaruw9uCAqV3CuoKJT2YoVFcw2cIdN4wM9rpwxLDIYB+pccPigxFT+wjrC+x4MvNK9QW2XrinDROBb1o4QVgisElqmrB04I3UlGGpwZPUQaj6uCP+6t/UeVEU3V0kpYi1pIUnYZVSQS4zgZ6qq4a6kQKU2vmA6a+ugThs8KtrCBI24I0UCBg2SGpgQiW7kQKhNhxq4cAkLNnCgVVYgtTAMKzX1MCcin4yA24b9r1wYB4WfeEQRVjE1BBRWJTUECnV+mS2+oyHEKtP/rA9TJ65WgEbPA7D3LzGnoGjpRqyx+DYNmyx8D9wEmFNUmeyKhMLu506k1KmrZ2YfwG5146czOJfBwAAAABJRU5ErkJggg==';
const _fictitiousPortraitPng =
    'iVBORw0KGgoAAAANSUhEUgAAADIAAABQCAIAAADUYbG3AAACV0lEQVR42s2aIXICQRBFm194DB4bAyY6J+AGmHhOQAwCww3wMZyAnCAasyoWH8MJiNhksuwuuzM9v2enFWOoV+91UTXUjOabU7FfLt4+JI+5HteT1WF0u93Kcw5k1+O6/IB8PLmZrA5wh2K/zESViCCTfFVVv1g5CKuq+sdywgYhc0ylqjtbg6d0TPWIgwir5WvBSp+yma/d1iApa0ztEZMJa81Xzmi+OVXPn09bEZm8nkXk+v5sirXYfotIsZuWx5evXb8tB2fK9GjasZwnIzLH5FT57pZ1wQ6mnohGwrrz9WNZpOzN52XLKGU3k1dEojCffL5YdGG9qgJsxQvzV+WLFb/7npsebIuS0pMpLKJaWFC+YCxdytB8GlvqlEFMmohBwhT5lFgKYaGq9LZ8hKlVKbF8dl+36bG2PFPqmKIidgiLyReL1StMrYpgqyksXlUsVnP3IzedZqs1ZSSTiIxpF/bX82w2Y30bYbdKYY4pXhUHq5qSwkTDcpvOurpBeHO5XDLardoPFUUYWEzFbkq8hXMiuk1nXSpBzEdMCUo++h8qYOXjXipBz0dJCboqijDYqYoRBtamc/9QAT0fJSXs8sWkhJ2qGGFIoEohDPRNp+w+7PLFpESCfIqUMM2nTgnrfLqUSJYvKCWSqQoShvSqfITBetN1u49k+YJSIn0+n5RImc8/JRLn80w5fqSq+ljCboo/YbVHNO22mo9ejObRk547rI5HL+ba7p/0oMmUTFVNWJUMQ+XrTonB87WmxID5OlJi2HyPUiKTfLWUyERVTRgky/kBkb4xdYhZ9bAAAAAASUVORK5CYII=';
