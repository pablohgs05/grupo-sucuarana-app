import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/operational_report.dart';
import 'package:grupo_sucuarana_app/report_attachment.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_review_page.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  testWidgets('revisão mostra dados estruturados sem expor caminho local',
      (tester) async {
    final report = _reviewReport();

    await tester.pumpWidget(
      MaterialApp(home: ReportReviewPage(report: report)),
    );

    expect(find.text('Revisar relatório'), findsOneWidget);

    final reviewScroll = find.descendant(
      of: find.byKey(const ValueKey('report-review-list')),
      matching: find.byType(Scrollable),
    );

    final personSection = find.byKey(
      const ValueKey('review-section-person'),
    );
    await tester.scrollUntilVisible(
      personSection,
      300,
      scrollable: reviewScroll,
    );
    expect(find.text('Pessoa fictícia de revisão'), findsOneWidget);

    final transportSection = find.byKey(
      const ValueKey('review-section-transportation'),
    );
    await tester.scrollUntilVisible(
      transportSection,
      300,
      scrollable: reviewScroll,
    );
    expect(find.text('Bicicleta fictícia'), findsOneWidget);

    final healthSection = find.byKey(
      const ValueKey('review-section-healthAndBehavior'),
    );
    await tester.scrollUntilVisible(
      healthSection,
      400,
      scrollable: reviewScroll,
    );
    expect(find.text('Detalhe oculto antigo'), findsNothing);

    final attachmentsSection = find.byKey(
      const ValueKey('review-section-conclusionAndAttachments'),
    );
    await tester.scrollUntilVisible(
      attachmentsSection,
      600,
      scrollable: reviewScroll,
    );

    expect(
      find.text('anexo-revisao.jpg — Legenda fictícia'),
      findsOneWidget,
    );
    expect(find.text('/managed/ficticio/anexo-revisao.jpg'), findsNothing);
  });

  testWidgets('editar seção retorna identificador estável ao formulário',
      (tester) async {
    ReportReviewResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ReportReviewResult>(
                    MaterialPageRoute(
                      builder: (_) => ReportReviewPage(
                        report: _reviewReport(),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir revisão'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir revisão'));
    await tester.pumpAndSettle();

    final editPerson = find.byKey(const ValueKey('edit-person'));
    await tester.scrollUntilVisible(
      editPerson,
      250,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('report-review-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(editPerson);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.confirmed, isFalse);
    expect(result!.editSection, 'person');
  });

  testWidgets('confirmar revisão retorna confirmação explícita',
      (tester) async {
    ReportReviewResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<ReportReviewResult>(
                    MaterialPageRoute(
                      builder: (_) => ReportReviewPage(
                        report: _reviewReport(),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir revisão'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir revisão'));
    await tester.pumpAndSettle();

    final confirm = find.byKey(const ValueKey('confirm-review'));
    await tester.scrollUntilVisible(
      confirm,
      700,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('report-review-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.confirmed, isTrue);
    expect(result!.editSection, isNull);
  });
}

Report _reviewReport() => Report(
      id: 'review-report-ficticio',
      identification: Identification(
        title: 'Relatório de revisão fictício',
        date: DateTime.utc(2026, 10, 5),
        coordinator: 'Equipe fictícia',
      ),
      searchTriage: const SearchTriage(
        metadata: TriageMetadata(
          formNumber: 'FORM-REVISAO-FICTICIO',
          factDate: '05/10/2026',
          factTime: '10:00',
          noticeDate: '05/10/2026',
          noticeTime: '10:30',
        ),
        person: PersonIdentification(
          name: 'Pessoa fictícia de revisão',
          nickname: '',
          address: 'Endereço fictício',
          contacts: <String>['Contato fictício'],
          additionalAddresses: <String>[],
          referenceContact: 'Referência fictícia',
        ),
        relatedPeople: <RelatedPerson>[],
        historyAndDestination: HistoryAndDestination(
          narrative: 'Histórico fictício.',
          recurringMotivation: AnswerState.no,
          intendedDestination: '',
        ),
        transportation: Transportation(
          onFoot: AnswerState.no,
          bicycle: AnswerState.yes,
          bicycleMakeModel: 'Bicicleta fictícia',
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
        lastSeen: LastSeen.empty,
        physicalDescription: PhysicalDescription.empty,
        clothingAndAccessories: ClothingAndAccessories.empty,
        personalSupplies: PersonalSupplies.empty,
        healthAndBehavior: HealthAndBehavior(
          generalCondition: '',
          physicalDisabilities: '',
          diseases: '',
          psychologicalIssues: '',
          medicationUse: AnswerState.no,
          medicationDetails: 'Detalhe oculto antigo',
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
        experienceAndResistance: ExperienceAndResistance.empty,
        previousActions: PreviousActions.empty,
      ),
      operation: const Operation(
        location: 'Local fictício',
        start: '08:00',
        end: '12:00',
      ),
      operationalContent: const OperationalReportContent(
        generalInformation: OperationalGeneralInformation.empty,
        occurrenceNarrative: 'Ocorrência fictícia.',
        developmentNarrative: 'Desenvolvimento fictício.',
        teams: <OperationalTeam>[],
        resources: <OperationalResource>[],
        conclusion: 'Conclusão fictícia.',
      ),
      attachmentItems: const <ReportAttachment>[
        ReportAttachment(
          id: 'review-att-001',
          localPath: '/managed/ficticio/anexo-revisao.jpg',
          originalName: 'anexo-revisao.jpg',
          caption: 'Legenda fictícia',
          managedLocalFile: true,
        ),
      ],
      createdAt: DateTime.utc(2026, 10, 5, 9),
      updatedAt: DateTime.utc(2026, 10, 5, 12),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 16,
      lastEditedSection: 'conclusionAndAttachments',
      syncStatus: SyncStatus.pending,
    );
