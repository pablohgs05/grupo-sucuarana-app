import 'package:flutter/material.dart';

import 'report_model.dart';
import 'search_triage.dart';

class ReportReviewResult {
  const ReportReviewResult.confirm()
      : confirmed = true,
        editSection = null;

  const ReportReviewResult.edit(this.editSection) : confirmed = false;

  final bool confirmed;
  final String? editSection;
}

class ReportReviewPage extends StatelessWidget {
  const ReportReviewPage({
    super.key,
    required this.report,
  });

  final Report report;

  @override
  Widget build(BuildContext context) {
    final triage = report.searchTriage;
    final operational = report.operationalContent;

    final sections = <_ReviewSection>[
      _ReviewSection(
        id: 'identification',
        title: 'Identificação',
        rows: [
          _row('Título', report.identification.title),
          _row('Data', _date(report.identification.date)),
          _row('Coordenação/equipe', report.identification.coordinator),
        ],
      ),
      _ReviewSection(
        id: 'triageMetadata',
        title: 'Dados do formulário',
        rows: [
          _row('Número do formulário', triage.metadata.formNumber),
          _row('Data do fato', triage.metadata.factDate),
          _row('Hora do fato', triage.metadata.factTime),
          _row('Data do aviso', triage.metadata.noticeDate),
          _row('Hora do aviso', triage.metadata.noticeTime),
        ],
      ),
      _ReviewSection(
        id: 'person',
        title: 'Pessoa e contatos',
        rows: [
          _row('Nome', triage.person.name),
          _row('Apelido', triage.person.nickname),
          _row('Endereço', triage.person.address),
          _row(
            'Outros endereços',
            _list(triage.person.additionalAddresses),
          ),
          _row('Contato de referência', triage.person.referenceContact),
          _row('Outros contatos', _list(triage.person.contacts)),
          _row(
            'Pessoas relacionadas',
            _list(
              triage.relatedPeople.map((item) {
                final parts = <String>[
                  item.relation,
                  item.name,
                  item.contact,
                ].where((part) => part.trim().isNotEmpty).toList();
                return parts.join(' • ');
              }),
            ),
          ),
        ],
      ),
      _ReviewSection(
        id: 'history',
        title: 'Histórico e destino',
        rows: [
          _row('Histórico / motivação', triage.historyAndDestination.narrative),
          _row(
            'Situação recorrente',
            _answer(triage.historyAndDestination.recurringMotivation),
          ),
          _row(
            'Destino pretendido',
            triage.historyAndDestination.intendedDestination,
          ),
        ],
      ),
      _ReviewSection(
        id: 'transportation',
        title: 'Transporte',
        rows: _transportRows(triage),
      ),
      _ReviewSection(
        id: 'lastSeen',
        title: 'Último avistamento',
        rows: [
          _row('Quando', triage.lastSeen.when),
          _row('Onde', triage.lastSeen.where),
          _row('Direção/destino', triage.lastSeen.intendedDirection),
          _row('Testemunha', triage.lastSeen.witnessName),
          _row('Endereço da testemunha', triage.lastSeen.witnessAddress),
          _row('Contato da testemunha', triage.lastSeen.witnessContact),
          _row('Observações', triage.lastSeen.notes),
        ],
      ),
      _ReviewSection(
        id: 'physicalDescription',
        title: 'Descrição física',
        rows: [
          _row('Idade', triage.physicalDescription.age),
          _row('Cor/característica de pele', triage.physicalDescription.color),
          _row('Altura', triage.physicalDescription.height),
          _row('Cabelos', triage.physicalDescription.hair),
          _row('Barba', _answer(triage.physicalDescription.beard)),
          _row('Outras características', triage.physicalDescription.notes),
        ],
      ),
      _ReviewSection(
        id: 'clothingAndSupplies',
        title: 'Vestimentas e materiais',
        rows: [
          _row(
            'Vestimentas/acessórios',
            _list(
              triage.clothingAndAccessories.items.map((item) {
                final details = <String>[
                  item.item,
                  item.type,
                  item.color,
                  item.materialOrPattern,
                  item.size,
                  item.model,
                ].where((part) => part.trim().isNotEmpty).toList();
                return details.join(' • ');
              }),
            ),
          ),
          _row(
            'Observações',
            triage.clothingAndAccessories.notes,
          ),
          _row(
            'Materiais/equipamentos pessoais',
            triage.personalSupplies.notes,
          ),
        ],
      ),
      _ReviewSection(
        id: 'healthAndBehavior',
        title: 'Saúde e comportamento',
        rows: _healthRows(triage),
      ),
      _ReviewSection(
        id: 'experienceAndResistance',
        title: 'Experiência e resistência',
        rows: _experienceRows(triage),
      ),
      _ReviewSection(
        id: 'previousActions',
        title: 'Procedimentos anteriores',
        rows: [
          _row('Medidas e resultados', triage.previousActions.description),
        ],
      ),
      _ReviewSection(
        id: 'generalInformation',
        title: 'Informações gerais do relatório',
        rows: [
          _row(
            'Referência externa/boletim',
            operational.generalInformation.externalReference,
          ),
          _row('RG', operational.generalInformation.documentRg),
          _row('CPF', operational.generalInformation.documentCpf),
          _row('Telefone', operational.generalInformation.phone),
          _row(
            'Contato feito por',
            operational.generalInformation.contactMadeBy,
          ),
        ],
      ),
      _ReviewSection(
        id: 'occurrenceNarrative',
        title: 'Descrição da ocorrência',
        rows: [
          _row('Narrativa', operational.occurrenceNarrative),
        ],
      ),
      _ReviewSection(
        id: 'operation',
        title: 'Operação',
        rows: [
          _row('Local', report.operation.location),
          _row('Início', report.operation.start),
          _row('Término', report.operation.end),
        ],
      ),
      _ReviewSection(
        id: 'teamsAndResources',
        title: 'Desenvolvimento e equipes',
        rows: [
          _row('Desenvolvimento', operational.developmentNarrative),
          _row(
            'Equipes',
            _list(
              operational.teams.map((team) {
                final members = team.members.isEmpty
                    ? ''
                    : ' — ${team.members.join(', ')}';
                return '${team.name}$members';
              }),
            ),
          ),
        ],
      ),
      _ReviewSection(
        id: 'resources',
        title: 'Recursos utilizados',
        rows: [
          _row(
            'Recursos',
            _list(
              operational.resources.map((resource) {
                if (resource.purpose.trim().isEmpty) {
                  return resource.description;
                }
                return '${resource.description} — ${resource.purpose}';
              }),
            ),
          ),
        ],
      ),
      _ReviewSection(
        id: 'conclusionAndAttachments',
        title: 'Conclusão e anexos',
        rows: [
          _row('Conclusão', operational.conclusion),
          _row(
            'Anexos',
            _list(
              report.attachmentItems.map((attachment) {
                final caption = attachment.caption.trim();
                return caption.isEmpty
                    ? attachment.originalName
                    : '${attachment.originalName} — $caption';
              }),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar relatório')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Confira os dados antes de concluir. Campos sem conteúdo '
                'aparecem como “Não informado”; esta etapa não cria novas '
                'regras de obrigatoriedade.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sections.map(
            (section) => _ReviewSectionCard(section: section),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('confirm-review'),
            onPressed: () => Navigator.of(context).pop(
              const ReportReviewResult.confirm(),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar revisão'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar sem concluir'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static List<_ReviewRow> _transportRows(SearchTriage triage) {
    final transport = triage.transportation;
    return [
      _row('Saiu a pé', _answer(transport.onFoot)),
      _row('Bicicleta', _answer(transport.bicycle)),
      _row('Bicicleta - marca/modelo', transport.bicycleMakeModel),
      _row('Bicicleta - cor', transport.bicycleColor),
      _row('Bicicleta - tamanho', transport.bicycleSize),
      _row('Veículo motorizado', _answer(transport.motorVehicle)),
      _row('Veículo - tipo', transport.motorVehicleType),
      _row('Veículo - marca/modelo', transport.motorVehicleMakeModel),
      _row('Veículo - cor', transport.motorVehicleColor),
      _row('Veículo - placa', transport.motorVehiclePlate),
      _row('Montaria', _answer(transport.mount)),
      _row('Montaria - tipo', transport.mountType),
      _row('Montaria - cor', transport.mountColor),
      _row(
        'Veículo/montaria localizado',
        _answer(transport.vehicleOrMountFound),
      ),
      _row(
        'Detalhes da localização',
        transport.vehicleOrMountFoundDetails,
      ),
      _row('Montaria retornou', _answer(transport.mountReturned)),
      _row('Detalhes do retorno', transport.mountReturnDetails),
    ];
  }

  static List<_ReviewRow> _healthRows(SearchTriage triage) {
    final health = triage.healthAndBehavior;
    return [
      _row('Condição geral', health.generalCondition),
      _row('Deficiências físicas', health.physicalDisabilities),
      _row('Doenças/condições', health.diseases),
      _row('Questões psicológicas/comportamentais', health.psychologicalIssues),
      _row('Uso de medicamento', _answer(health.medicationUse)),
      _row('Medicamentos/detalhes', health.medicationDetails),
      _row('Tomou a medicação', _answer(health.tookMedication)),
      _row(
        'Consequências da falta do medicamento',
        health.lackOfMedicationConsequences,
      ),
      _row('Uso de drogas', _answer(health.drugUse)),
      _row('Detalhes sobre uso de drogas', health.drugDetails),
      _row('Conflitos familiares', _answer(health.familyConflicts)),
      _row('Conflito no trabalho', _answer(health.workConflict)),
      _row('Problemas financeiros', _answer(health.financialProblems)),
      _row(
        'Tentativa anterior de autoagressão',
        _answer(health.previousSelfHarmAttempt),
      ),
      _row('Detalhes da tentativa', health.previousSelfHarmDetails),
      _row(
        'Ameaça anterior de autoagressão',
        _answer(health.previousSelfHarmThreat),
      ),
      _row('Detalhes da ameaça', health.previousSelfHarmThreatDetails),
      _row('Outras observações', health.notes),
    ];
  }

  static List<_ReviewRow> _experienceRows(SearchTriage triage) {
    final experience = triage.experienceAndResistance;
    return [
      _row(
        'Experiência em caminhada/área rural',
        _answer(experience.ruralWalking),
      ),
      _row('Detalhes da experiência', experience.ruralWalkingDetails),
      _row('Conhece a área', _answer(experience.knowsArea)),
      _row('Desde quando/nível de conhecimento', experience.knowsAreaSince),
      _row('Já se perdeu anteriormente', _answer(experience.previouslyLost)),
      _row('Detalhes da ocorrência anterior', experience.previousLostDetails),
      _row('Resistência/condicionamento', experience.physicalResistance),
      _row('Sabe nadar', _answer(experience.canSwim)),
    ];
  }

  static _ReviewRow _row(String label, String value) =>
      _ReviewRow(label, _value(value));

  static String _value(String value) =>
      value.trim().isEmpty ? 'Não informado' : value.trim();

  static String _list(Iterable<String> values) {
    final filtered = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return filtered.isEmpty ? 'Não informado' : filtered.join('\n');
  }

  static String _answer(AnswerState state) => switch (state) {
        AnswerState.yes => 'Sim',
        AnswerState.no => 'Não',
        AnswerState.unknown => 'Não informado',
      };

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

class _ReviewSectionCard extends StatelessWidget {
  const _ReviewSectionCard({required this.section});

  final _ReviewSection section;

  @override
  Widget build(BuildContext context) => Card(
        key: ValueKey('review-section-${section.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    key: ValueKey('edit-${section.id}'),
                    onPressed: () => Navigator.of(context).pop(
                      ReportReviewResult.edit(section.id),
                    ),
                    child: const Text('Editar'),
                  ),
                ],
              ),
              const Divider(),
              ...section.rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      SelectableText(row.value),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ReviewSection {
  const _ReviewSection({
    required this.id,
    required this.title,
    required this.rows,
  });

  final String id;
  final String title;
  final List<_ReviewRow> rows;
}

class _ReviewRow {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;
}
