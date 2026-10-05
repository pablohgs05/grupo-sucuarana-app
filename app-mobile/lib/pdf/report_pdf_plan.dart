import '../report_attachment.dart';
import '../report_model.dart';
import '../search_triage.dart';

class ReportPdfBranding {
  const ReportPdfBranding({
    required this.organization,
    required this.tagline,
    required this.registrationLine,
    required this.email,
    required this.siteLine,
  });

  static const institutional = ReportPdfBranding(
    organization: 'Grupo Suçuarana Operações Socioambientais',
    tagline: 'Desde 1994Preservando a Vida e o Meio Ambiente',
    registrationLine:
        'CNPJ. 00.616.841.0001/28 - Utilidade Pública Lei nº 5.067/97.',
    email: 'OPERACAO.GSOS@SUSSUARANA.ORG.BR',
    siteLine: 'WWW.SUSSURANA.ORG.BR - WWW.SUCUARANA.ORG.BR',
  );

  final String organization;
  final String tagline;
  final String registrationLine;
  final String email;
  final String siteLine;
}

class ReportPdfPlan {
  const ReportPdfPlan({
    required this.branding,
    required this.title,
    required this.coordinator,
    required this.location,
    required this.dateLabel,
    required this.monthYearLabel,
    required this.formNumber,
    required this.externalReference,
    required this.generalInformation,
    required this.occurrenceNarrative,
    required this.operationInformation,
    required this.developmentNarrative,
    required this.teams,
    required this.resources,
    required this.conclusion,
    required this.triageGroups,
    required this.attachments,
  });

  final ReportPdfBranding branding;
  final String title;
  final String coordinator;
  final String location;
  final String dateLabel;
  final String monthYearLabel;
  final String formNumber;
  final String externalReference;
  final List<ReportPdfField> generalInformation;
  final String occurrenceNarrative;
  final List<ReportPdfField> operationInformation;
  final String developmentNarrative;
  final List<ReportPdfTeam> teams;
  final List<ReportPdfResource> resources;
  final String conclusion;
  final List<ReportPdfGroup> triageGroups;
  final List<ReportAttachment> attachments;

  factory ReportPdfPlan.fromReport(
    Report report, {
    ReportPdfBranding branding = ReportPdfBranding.institutional,
  }) {
    final triage = report.searchTriage;
    final operational = report.operationalContent;
    final info = operational.generalInformation;

    return ReportPdfPlan(
      branding: branding,
      title: _value(report.identification.title),
      coordinator: _value(report.identification.coordinator),
      location: _value(report.operation.location),
      dateLabel: _date(report.identification.date),
      monthYearLabel: _monthYear(report.identification.date),
      formNumber: _value(triage.metadata.formNumber),
      externalReference: _value(info.externalReference),
      generalInformation: <ReportPdfField>[
        ReportPdfField('Nome', _value(triage.person.name)),
        ReportPdfField('Endereço', _value(triage.person.address)),
        ReportPdfField('RG', _value(info.documentRg)),
        ReportPdfField('CPF', _value(info.documentCpf)),
        ReportPdfField('Telefone', _value(info.phone)),
        ReportPdfField('Contato feito por', _value(info.contactMadeBy)),
        ReportPdfField(
          'Referência externa / boletim',
          _value(info.externalReference),
        ),
      ],
      occurrenceNarrative: _value(operational.occurrenceNarrative),
      operationInformation: <ReportPdfField>[
        ReportPdfField('Local', _value(report.operation.location)),
        ReportPdfField('Início', _value(report.operation.start)),
        ReportPdfField('Término', _value(report.operation.end)),
      ],
      developmentNarrative: _value(operational.developmentNarrative),
      teams: operational.teams
          .map(
            (team) => ReportPdfTeam(
              name: _value(team.name),
              members: team.members
                  .map(_value)
                  .where((value) => value != _notInformed)
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
      resources: operational.resources
          .map(
            (resource) => ReportPdfResource(
              description: _value(resource.description),
              purpose: _value(resource.purpose),
            ),
          )
          .toList(growable: false),
      conclusion: _value(operational.conclusion),
      triageGroups: _triageGroups(triage),
      attachments: List<ReportAttachment>.unmodifiable(
        report.attachmentItems,
      ),
    );
  }

  static List<ReportPdfGroup> _triageGroups(SearchTriage triage) => [
        ReportPdfGroup(
          title: 'INFORMAÇÕES GERAIS',
          fields: [
            ReportPdfField('Data do fato', _value(triage.metadata.factDate)),
            ReportPdfField('Hora do fato', _value(triage.metadata.factTime)),
            ReportPdfField('Data do aviso', _value(triage.metadata.noticeDate)),
            ReportPdfField('Hora do aviso', _value(triage.metadata.noticeTime)),
            ReportPdfField('Nome', _value(triage.person.name)),
            ReportPdfField('Apelido', _value(triage.person.nickname)),
            ReportPdfField('Endereço', _value(triage.person.address)),
            ReportPdfField(
              'Contato de referência',
              _value(triage.person.referenceContact),
            ),
            ReportPdfField(
              'Outros contatos',
              _list(triage.person.contacts),
            ),
            ReportPdfField(
              'Endereços adicionais',
              _list(triage.person.additionalAddresses),
            ),
            ReportPdfField(
              'Familiares / amigos / relacionados',
              _list(
                triage.relatedPeople.map((person) {
                  final parts = <String>[
                    person.relation.trim(),
                    person.name.trim(),
                    person.contact.trim(),
                  ].where((part) => part.isNotEmpty).toList(growable: false);
                  return parts.join(' - ');
                }),
              ),
            ),
          ],
        ),
        ReportPdfGroup(
          title: 'MOTIVAÇÃO / HISTÓRIA / DESTINO',
          fields: [
            ReportPdfField(
              'Histórico / motivação',
              _value(triage.historyAndDestination.narrative),
            ),
            ReportPdfField(
              'A motivação é costumeira?',
              _answer(triage.historyAndDestination.recurringMotivation),
            ),
            ReportPdfField(
              'Destino pretendido / possível destino',
              _value(triage.historyAndDestination.intendedDestination),
            ),
          ],
        ),
        ReportPdfGroup(
          title: 'MEIO DE TRANSPORTE',
          fields: _transportFields(triage),
        ),
        ReportPdfGroup(
          title: 'VISTO PELA ÚLTIMA VEZ',
          fields: [
            ReportPdfField('Quando', _value(triage.lastSeen.when)),
            ReportPdfField('Onde', _value(triage.lastSeen.where)),
            ReportPdfField(
              'Direção / destino indicado',
              _value(triage.lastSeen.intendedDirection),
            ),
            ReportPdfField(
              'Nome da testemunha',
              _value(triage.lastSeen.witnessName),
            ),
            ReportPdfField(
              'Endereço da testemunha',
              _value(triage.lastSeen.witnessAddress),
            ),
            ReportPdfField(
              'Contato da testemunha',
              _value(triage.lastSeen.witnessContact),
            ),
            ReportPdfField('Observações', _value(triage.lastSeen.notes)),
          ],
        ),
        ReportPdfGroup(
          title: 'DESCRIÇÃO FÍSICA',
          fields: [
            ReportPdfField('Idade', _value(triage.physicalDescription.age)),
            ReportPdfField(
              'Cor / característica de pele',
              _value(triage.physicalDescription.color),
            ),
            ReportPdfField('Altura', _value(triage.physicalDescription.height)),
            ReportPdfField('Cabelos', _value(triage.physicalDescription.hair)),
            ReportPdfField(
              'Barba',
              _answer(triage.physicalDescription.beard),
            ),
            ReportPdfField(
              'Outras características',
              _value(triage.physicalDescription.notes),
            ),
          ],
        ),
        ReportPdfGroup(
          title: 'VESTIMENTAS / ACESSÓRIOS',
          fields: [
            ReportPdfField(
              'Itens',
              _list(
                triage.clothingAndAccessories.items.map((item) {
                  final values = <String>[
                    item.item,
                    item.type,
                    item.color,
                    item.materialOrPattern,
                    item.size,
                    item.model,
                  ].map((part) => part.trim()).where((part) => part.isNotEmpty);
                  return values.join(' - ');
                }),
              ),
            ),
            ReportPdfField(
              'Observações',
              _value(triage.clothingAndAccessories.notes),
            ),
          ],
        ),
        ReportPdfGroup(
          title: 'MATERIAIS / EQUIPAMENTOS / SUPRIMENTOS',
          fields: [
            ReportPdfField(
              'Materiais pessoais',
              _value(triage.personalSupplies.notes),
            ),
          ],
        ),
        ReportPdfGroup(
          title: 'SAÚDE E COMPORTAMENTO',
          fields: _healthFields(triage),
        ),
        ReportPdfGroup(
          title: 'EXPERIÊNCIA E RESISTÊNCIA FÍSICA',
          fields: _experienceFields(triage),
        ),
        ReportPdfGroup(
          title: 'PROCEDIMENTOS REALIZADOS ATÉ O MOMENTO',
          fields: [
            ReportPdfField(
              'Ações empreendidas e resultados',
              _value(triage.previousActions.description),
            ),
          ],
        ),
      ];

  static List<ReportPdfField> _transportFields(SearchTriage triage) {
    final value = triage.transportation;
    return [
      ReportPdfField('A pé', _answer(value.onFoot)),
      ReportPdfField('Bicicleta', _answer(value.bicycle)),
      if (value.bicycle == AnswerState.yes) ...[
        ReportPdfField('Bicicleta - marca/modelo', _value(value.bicycleMakeModel)),
        ReportPdfField('Bicicleta - cor', _value(value.bicycleColor)),
        ReportPdfField('Bicicleta - tamanho', _value(value.bicycleSize)),
      ],
      ReportPdfField('Veículo motorizado', _answer(value.motorVehicle)),
      if (value.motorVehicle == AnswerState.yes) ...[
        ReportPdfField('Veículo - tipo', _value(value.motorVehicleType)),
        ReportPdfField(
          'Veículo - marca/modelo',
          _value(value.motorVehicleMakeModel),
        ),
        ReportPdfField('Veículo - cor', _value(value.motorVehicleColor)),
        ReportPdfField('Veículo - placa', _value(value.motorVehiclePlate)),
      ],
      ReportPdfField('Montaria', _answer(value.mount)),
      if (value.mount == AnswerState.yes) ...[
        ReportPdfField('Montaria - tipo', _value(value.mountType)),
        ReportPdfField('Montaria - cor', _value(value.mountColor)),
      ],
      ReportPdfField(
        'Veículo ou montaria encontrado',
        _answer(value.vehicleOrMountFound),
      ),
      if (value.vehicleOrMountFound == AnswerState.yes)
        ReportPdfField(
          'Detalhes da localização',
          _value(value.vehicleOrMountFoundDetails),
        ),
      ReportPdfField('A montaria retornou', _answer(value.mountReturned)),
      if (value.mountReturned == AnswerState.yes)
        ReportPdfField(
          'Detalhes do retorno',
          _value(value.mountReturnDetails),
        ),
    ];
  }

  static List<ReportPdfField> _healthFields(SearchTriage triage) {
    final value = triage.healthAndBehavior;
    return [
      ReportPdfField('Condição geral', _value(value.generalCondition)),
      ReportPdfField(
        'Deficiências físicas',
        _value(value.physicalDisabilities),
      ),
      ReportPdfField('Doenças / condições', _value(value.diseases)),
      ReportPdfField(
        'Questões psicológicas / comportamentais',
        _value(value.psychologicalIssues),
      ),
      ReportPdfField('Usa medicamento', _answer(value.medicationUse)),
      if (value.medicationUse == AnswerState.yes) ...[
        ReportPdfField('Medicamentos / detalhes', _value(value.medicationDetails)),
        ReportPdfField('Tomou a medicação', _answer(value.tookMedication)),
        ReportPdfField(
          'Consequências da falta do medicamento',
          _value(value.lackOfMedicationConsequences),
        ),
      ],
      ReportPdfField('Uso de drogas', _answer(value.drugUse)),
      if (value.drugUse == AnswerState.yes)
        ReportPdfField('Detalhes sobre uso de drogas', _value(value.drugDetails)),
      ReportPdfField('Conflitos familiares', _answer(value.familyConflicts)),
      ReportPdfField('Conflito no trabalho', _answer(value.workConflict)),
      ReportPdfField('Problemas financeiros', _answer(value.financialProblems)),
      ReportPdfField(
        'Tentativa anterior de autoagressão',
        _answer(value.previousSelfHarmAttempt),
      ),
      if (value.previousSelfHarmAttempt == AnswerState.yes)
        ReportPdfField(
          'Detalhes da tentativa',
          _value(value.previousSelfHarmDetails),
        ),
      ReportPdfField(
        'Ameaça anterior de autoagressão',
        _answer(value.previousSelfHarmThreat),
      ),
      if (value.previousSelfHarmThreat == AnswerState.yes)
        ReportPdfField(
          'Detalhes da ameaça',
          _value(value.previousSelfHarmThreatDetails),
        ),
      ReportPdfField('Observações', _value(value.notes)),
    ];
  }

  static List<ReportPdfField> _experienceFields(SearchTriage triage) {
    final value = triage.experienceAndResistance;
    return [
      ReportPdfField(
        'Experiência em caminhada / área rural',
        _answer(value.ruralWalking),
      ),
      if (value.ruralWalking == AnswerState.yes)
        ReportPdfField(
          'Detalhes da experiência',
          _value(value.ruralWalkingDetails),
        ),
      ReportPdfField('Conhece a área', _answer(value.knowsArea)),
      if (value.knowsArea == AnswerState.yes)
        ReportPdfField(
          'Desde quando / nível de conhecimento',
          _value(value.knowsAreaSince),
        ),
      ReportPdfField('Já se perdeu anteriormente', _answer(value.previouslyLost)),
      if (value.previouslyLost == AnswerState.yes)
        ReportPdfField(
          'Detalhes de ocorrência anterior',
          _value(value.previousLostDetails),
        ),
      ReportPdfField(
        'Resistência / condicionamento físico',
        _value(value.physicalResistance),
      ),
      ReportPdfField('Sabe nadar', _answer(value.canSwim)),
    ];
  }
}

class ReportPdfField {
  const ReportPdfField(this.label, this.value);

  final String label;
  final String value;
}

class ReportPdfGroup {
  const ReportPdfGroup({
    required this.title,
    required this.fields,
  });

  final String title;
  final List<ReportPdfField> fields;
}

class ReportPdfTeam {
  const ReportPdfTeam({
    required this.name,
    required this.members,
  });

  final String name;
  final List<String> members;
}

class ReportPdfResource {
  const ReportPdfResource({
    required this.description,
    required this.purpose,
  });

  final String description;
  final String purpose;
}

const _notInformed = 'Não informado';

String _value(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? _notInformed : trimmed;
}

String _list(Iterable<String> values) {
  final filtered = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  return filtered.isEmpty ? _notInformed : filtered.join('\n');
}

String _answer(AnswerState value) => switch (value) {
      AnswerState.yes => 'Sim',
      AnswerState.no => 'Não',
      AnswerState.unknown => _notInformed,
    };

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/'
    '${value.year}';

String _monthYear(DateTime value) {
  const months = <String>[
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[value.month - 1]}/${value.year}';
}
