import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/operational_report.dart';
import 'package:grupo_sucuarana_app/pdf/report_pdf_plan.dart';
import 'package:grupo_sucuarana_app/report_attachment.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  test('monta plano institucional completo sem dados reais', () {
    final plan = ReportPdfPlan.fromReport(_report());

    expect(
      plan.branding.organization,
      'Grupo Suçuarana Operações Socioambientais',
    );
    expect(plan.title, 'Relatório institucional fictício');
    expect(plan.formNumber, 'FORM-FICTICIO-008');
    expect(plan.externalReference, 'BO-FICTICIO-123');
    expect(plan.generalInformation, hasLength(7));
    expect(plan.occurrenceNarrative, 'Descrição fictícia da ocorrência.');
    expect(plan.operationInformation.first.value, 'Área fictícia');
    expect(plan.teams.single.members, <String>['Integrante A', 'Integrante B']);
    expect(plan.resources.single.description, 'Drone fictício');
    expect(plan.triageGroups, hasLength(10));
    expect(plan.triageGroups.first.title, 'INFORMAÇÕES GERAIS');
    expect(
      plan.triageGroups.last.title,
      'PROCEDIMENTOS REALIZADOS ATÉ O MOMENTO',
    );
    expect(plan.attachments.map((item) => item.id).toList(),
        <String>['att-001', 'att-002']);
  });

  test('plano do PDF respeita condicionais da triagem', () {
    final report = _report(
      healthAndBehavior: HealthAndBehavior.empty.copyWith(
        medicationUse: AnswerState.no,
        medicationDetails: 'Detalhe antigo que deve permanecer oculto',
        drugUse: AnswerState.no,
        drugDetails: 'Outro detalhe antigo oculto',
      ),
    );

    final plan = ReportPdfPlan.fromReport(report);
    final health = plan.triageGroups.firstWhere(
      (group) => group.title == 'SAÚDE E COMPORTAMENTO',
    );
    final values = health.fields.map((field) => field.value).toList();

    expect(values, isNot(contains('Detalhe antigo que deve permanecer oculto')));
    expect(values, isNot(contains('Outro detalhe antigo oculto')));
    expect(
      health.fields.firstWhere((field) => field.label == 'Usa medicamento').value,
      'Não',
    );
  });

  test('campos vazios viram Não informado sem inventar conteúdo', () {
    final report = _report(
      searchTriage: SearchTriage.empty,
      operationalContent: OperationalReportContent.empty,
    );

    final plan = ReportPdfPlan.fromReport(report);

    expect(plan.formNumber, 'Não informado');
    expect(plan.externalReference, 'Não informado');
    expect(
      plan.generalInformation.firstWhere((field) => field.label == 'Nome').value,
      'Não informado',
    );
    expect(plan.occurrenceNarrative, 'Não informado');
  });
}

Report _report({
  SearchTriage? searchTriage,
  HealthAndBehavior? healthAndBehavior,
  OperationalReportContent? operationalContent,
}) {
  final triage = searchTriage ??
      SearchTriage.empty.copyWith(
        metadata: const TriageMetadata(
          formNumber: 'FORM-FICTICIO-008',
          factDate: '05/10/2026',
          factTime: '10:00',
          noticeDate: '05/10/2026',
          noticeTime: '10:30',
        ),
        person: const PersonIdentification(
          name: 'Pessoa fictícia',
          nickname: 'Apelido fictício',
          address: 'Endereço fictício',
          contacts: <String>['Contato fictício'],
          additionalAddresses: <String>[],
          referenceContact: 'Referência fictícia',
        ),
        transportation: const Transportation(
          onFoot: AnswerState.no,
          bicycle: AnswerState.yes,
          bicycleMakeModel: 'Modelo fictício',
          bicycleColor: 'Cor fictícia',
          bicycleSize: '',
          motorVehicle: AnswerState.no,
          motorVehicleType: '',
          motorVehicleMakeModel: '',
          motorVehicleColor: '',
          motorVehiclePlate: '',
          mount: AnswerState.no,
          mountType: '',
          mountColor: '',
          vehicleOrMountFound: AnswerState.unknown,
          vehicleOrMountFoundDetails: '',
          mountReturned: AnswerState.unknown,
          mountReturnDetails: '',
        ),
        healthAndBehavior: healthAndBehavior ??
            const HealthAndBehavior(
              generalCondition: 'Condição fictícia',
              physicalDisabilities: '',
              diseases: '',
              psychologicalIssues: '',
              medicationUse: AnswerState.no,
              medicationDetails: '',
              tookMedication: AnswerState.unknown,
              lackOfMedicationConsequences: '',
              drugUse: AnswerState.no,
              drugDetails: '',
              familyConflicts: AnswerState.unknown,
              workConflict: AnswerState.unknown,
              financialProblems: AnswerState.unknown,
              previousSelfHarmAttempt: AnswerState.no,
              previousSelfHarmDetails: '',
              previousSelfHarmThreat: AnswerState.no,
              previousSelfHarmThreatDetails: '',
              notes: '',
            ),
        previousActions: const PreviousActions(
          description: 'Procedimento fictício realizado.',
        ),
      );

  return Report(
    id: 'pdf-ficticio',
    identification: Identification(
      title: 'Relatório institucional fictício',
      date: DateTime.utc(2026, 10, 5),
      coordinator: 'Responsável fictício',
    ),
    searchTriage: triage,
    operation: const Operation(
      location: 'Área fictícia',
      start: '08:00',
      end: '12:00',
    ),
    operationalContent: operationalContent ??
        const OperationalReportContent(
          generalInformation: OperationalGeneralInformation(
            externalReference: 'BO-FICTICIO-123',
            documentRg: 'RG-FICTICIO',
            documentCpf: 'CPF-FICTICIO',
            phone: 'TELEFONE-FICTICIO',
            contactMadeBy: 'Contato institucional fictício',
          ),
          occurrenceNarrative: 'Descrição fictícia da ocorrência.',
          developmentNarrative: 'Desenvolvimento operacional fictício.',
          teams: <OperationalTeam>[
            OperationalTeam(
              name: 'Equipe fictícia',
              members: <String>['Integrante A', 'Integrante B'],
            ),
          ],
          resources: <OperationalResource>[
            OperationalResource(
              description: 'Drone fictício',
              purpose: 'Reconhecimento fictício',
            ),
          ],
          conclusion: 'Conclusão fictícia.',
        ),
    attachmentItems: const <ReportAttachment>[
      ReportAttachment(
        id: 'att-001',
        localPath: '/local/ficticio/a.jpg',
        originalName: 'a.jpg',
        caption: 'Imagem fictícia A',
        managedLocalFile: true,
      ),
      ReportAttachment(
        id: 'att-002',
        localPath: '/local/ficticio/b.jpg',
        originalName: 'b.jpg',
        caption: 'Imagem fictícia B',
        managedLocalFile: true,
      ),
    ],
    createdAt: DateTime.utc(2026, 10, 5, 8),
    updatedAt: DateTime.utc(2026, 10, 5, 12),
    lifecycle: ReportLifecycle.readyForReview,
    lastEditedStep: 16,
    lastEditedSection: 'conclusionAndAttachments',
    syncStatus: SyncStatus.pending,
  );
}
