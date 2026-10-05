import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  test('interpreta payload legado sem perder os campos existentes', () {
    final updatedAt = DateTime.utc(2026, 10, 1, 12, 30);
    final report = Report.fromJson({
      'id': 'legacy-report',
      'identification': {
        'title': 'Relatório legado fictício',
        'date': DateTime.utc(2026, 10, 1).toIso8601String(),
        'coordinator': 'Equipe fictícia',
      },
      'missing': {
        'name': 'Pessoa fictícia',
        'lastSeen': 'Último avistamento fictício',
        'contact': 'Contato fictício',
      },
      'operation': {
        'location': 'Cidade fictícia',
        'start': '08:00',
        'end': '12:00',
      },
      'physicalDescription': 'Descrição física fictícia',
      'clothing': 'Vestimenta fictícia',
      'health': 'Informação de saúde fictícia',
      'procedures': 'Procedimentos fictícios',
      'teams': <String>[],
      'resources': <String>[],
      'conclusion': '',
      'attachments': <String>[],
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': 'pending',
    });

    expect(report.createdAt, updatedAt);
    expect(report.lifecycle, ReportLifecycle.readyForReview);
    expect(report.lastEditedStep, 0);
    expect(report.searchTriage.person.name, 'Pessoa fictícia');
    expect(
      report.searchTriage.person.referenceContact,
      'Contato fictício',
    );
    expect(
      report.searchTriage.lastSeen.notes,
      'Último avistamento fictício',
    );
    expect(
      report.searchTriage.physicalDescription.notes,
      'Descrição física fictícia',
    );
    expect(
      report.searchTriage.clothingAndAccessories.notes,
      'Vestimenta fictícia',
    );
    expect(
      report.searchTriage.healthAndBehavior.notes,
      'Informação de saúde fictícia',
    );
    expect(
      report.searchTriage.previousActions.description,
      'Procedimentos fictícios',
    );
    expect(report.toJson()['searchTriage'], isA<Map<String, dynamic>>());
  });

  test('preserva o formulário de triagem completo no round-trip JSON', () {
    final report = _report(searchTriage: _completeTriage());

    final decoded = Report.fromJson(report.toJson());

    expect(decoded.toJson(), report.toJson());
    expect(decoded.searchTriage.relatedPeople, hasLength(2));
    expect(
      decoded.searchTriage.healthAndBehavior.medicationUse,
      AnswerState.yes,
    );
    expect(
      decoded.searchTriage.experienceAndResistance.canSwim,
      AnswerState.unknown,
    );
    expect(
      decoded.searchTriage.clothingAndAccessories.items.single.item,
      'Camiseta',
    );
  });

  test('edição pelo formulário legado preserva os campos estruturados', () {
    final original = _report(searchTriage: _completeTriage());

    final edited = Report(
      id: original.id,
      identification: original.identification,
      searchTriage: original.searchTriage,
      missing: const MissingPerson(
        name: 'Pessoa fictícia editada',
        lastSeen: 'Resumo de último avistamento editado',
        contact: 'Contato fictício editado',
      ),
      operation: original.operation,
      physicalDescription: 'Observação física editada',
      clothing: 'Observação de roupa editada',
      health: 'Observação de saúde editada',
      procedures: 'Procedimentos editados',
      teams: original.teams,
      resources: original.resources,
      conclusion: original.conclusion,
      attachments: original.attachments,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
      lifecycle: original.lifecycle,
      lastEditedStep: original.lastEditedStep,
      syncStatus: original.syncStatus,
    );

    expect(edited.searchTriage.metadata.toJson(),
        original.searchTriage.metadata.toJson());
    expect(
      edited.searchTriage.relatedPeople.map((item) => item.toJson()).toList(),
      original.searchTriage.relatedPeople
          .map((item) => item.toJson())
          .toList(),
    );
    expect(
      edited.searchTriage.transportation.toJson(),
      original.searchTriage.transportation.toJson(),
    );
    expect(
      edited.searchTriage.experienceAndResistance.toJson(),
      original.searchTriage.experienceAndResistance.toJson(),
    );
    expect(edited.searchTriage.person.name, 'Pessoa fictícia editada');
    expect(
      edited.searchTriage.lastSeen.notes,
      'Resumo de último avistamento editado',
    );
    expect(
      edited.searchTriage.physicalDescription.notes,
      'Observação física editada',
    );
    expect(
      edited.searchTriage.previousActions.description,
      'Procedimentos editados',
    );
  });

  test('preserva identificador estável da seção em edição', () {
    final report = _report().copyWith(
      lastEditedStep: 4,
      lastEditedSection: 'transportation',
    );

    final decoded = Report.fromJson(report.toJson());

    expect(decoded.lastEditedStep, 4);
    expect(decoded.lastEditedSection, 'transportation');
  });

  test('valor desconhecido de sim ou não permanece unknown', () {
    final json = _completeTriage().toJson();
    final history =
        Map<String, dynamic>.from(json['historyAndDestination']! as Map);
    history['recurringMotivation'] = 'not-informed';
    json['historyAndDestination'] = history;

    final decoded = SearchTriage.fromJson(json);

    expect(
      decoded.historyAndDestination.recurringMotivation,
      AnswerState.unknown,
    );
  });
}

Report _report({SearchTriage? searchTriage}) => Report(
      id: 'report-m3-ficticio',
      identification: Identification(
        title: 'Relatório fictício M3',
        date: DateTime.utc(2026, 10, 2),
        coordinator: 'Equipe fictícia',
      ),
      searchTriage: searchTriage,
      operation: const Operation(
        location: 'Local fictício',
        start: '08:00',
        end: '12:00',
      ),
      teams: const <String>['Equipe fictícia A'],
      resources: const <String>['Recurso fictício'],
      conclusion: 'Conclusão fictícia.',
      attachments: const <String>[],
      createdAt: DateTime.utc(2026, 10, 2, 8),
      updatedAt: DateTime.utc(2026, 10, 2, 9),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 2,
      syncStatus: SyncStatus.pending,
    );

SearchTriage _completeTriage() => const SearchTriage(
      metadata: TriageMetadata(
        formNumber: 'FORM-TESTE',
        factDate: '01/10/2026',
        factTime: '10:00',
        noticeDate: '01/10/2026',
        noticeTime: '11:00',
      ),
      person: PersonIdentification(
        name: 'Pessoa Alfa',
        nickname: 'Alfa',
        address: 'Endereço fictício',
        contacts: <String>['Contato 1', 'Contato 2'],
        additionalAddresses: <String>['Endereço adicional fictício'],
        referenceContact: 'Contato de referência fictício',
      ),
      relatedPeople: <RelatedPerson>[
        RelatedPerson(
          relation: 'Familiar',
          name: 'Pessoa Beta',
          contact: 'Contato fictício Beta',
        ),
        RelatedPerson(
          relation: 'Amigo',
          name: 'Pessoa Gama',
          contact: 'Contato fictício Gama',
        ),
      ],
      historyAndDestination: HistoryAndDestination(
        narrative: 'Histórico fictício.',
        recurringMotivation: AnswerState.no,
        intendedDestination: 'Destino fictício.',
      ),
      transportation: Transportation(
        onFoot: AnswerState.yes,
        bicycle: AnswerState.no,
        bicycleMakeModel: '',
        bicycleColor: '',
        bicycleSize: '',
        motorVehicle: AnswerState.unknown,
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
      lastSeen: LastSeen(
        when: '01/10/2026 10:00',
        where: 'Local fictício de último avistamento',
        intendedDirection: 'Direção fictícia',
        witnessName: 'Testemunha fictícia',
        witnessAddress: 'Endereço fictício da testemunha',
        witnessContact: 'Contato fictício da testemunha',
        notes: '',
      ),
      physicalDescription: PhysicalDescription(
        age: '30',
        color: 'Informação fictícia',
        height: '1,70 m',
        hair: 'Informação fictícia',
        beard: AnswerState.no,
        notes: 'Observação física fictícia.',
      ),
      clothingAndAccessories: ClothingAndAccessories(
        items: <ClothingItem>[
          ClothingItem(
            item: 'Camiseta',
            type: '',
            color: 'Cor fictícia',
            materialOrPattern: 'Estampa fictícia',
            size: '',
            model: '',
          ),
        ],
        notes: 'Acessórios fictícios.',
      ),
      personalSupplies: PersonalSupplies(
        notes: 'Suprimentos pessoais fictícios.',
      ),
      healthAndBehavior: HealthAndBehavior(
        generalCondition: 'Condição geral fictícia.',
        physicalDisabilities: 'Não informado no teste.',
        diseases: 'Não informado no teste.',
        psychologicalIssues: 'Não informado no teste.',
        medicationUse: AnswerState.yes,
        medicationDetails: 'Medicamento fictício.',
        tookMedication: AnswerState.unknown,
        lackOfMedicationConsequences: 'Consequência fictícia.',
        drugUse: AnswerState.no,
        drugDetails: '',
        familyConflicts: AnswerState.unknown,
        workConflict: AnswerState.no,
        financialProblems: AnswerState.unknown,
        previousSelfHarmAttempt: AnswerState.no,
        previousSelfHarmDetails: '',
        previousSelfHarmThreat: AnswerState.no,
        previousSelfHarmThreatDetails: '',
        notes: 'Observação de saúde fictícia.',
      ),
      experienceAndResistance: ExperienceAndResistance(
        ruralWalking: AnswerState.yes,
        ruralWalkingDetails: 'Experiência fictícia em área rural.',
        knowsArea: AnswerState.no,
        knowsAreaSince: '',
        previouslyLost: AnswerState.no,
        previousLostDetails: '',
        physicalResistance: 'Resistência fictícia.',
        canSwim: AnswerState.unknown,
      ),
      previousActions: PreviousActions(
        description: 'Procedimentos anteriores fictícios.',
      ),
    );
