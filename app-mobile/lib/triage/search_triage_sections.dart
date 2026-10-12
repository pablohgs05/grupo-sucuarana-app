import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../search_triage.dart';
import '../structured_input_formatters.dart';

enum SearchTriageSection {
  metadata,
  person,
  history,
  transportation,
  lastSeen,
  physicalDescription,
  clothingAndSupplies,
  healthAndBehavior,
  experienceAndResistance,
  previousActions,
}

class SearchTriageSectionView extends StatelessWidget {
  const SearchTriageSectionView({
    super.key,
    required this.section,
    required this.value,
    required this.onChanged,
  });

  final SearchTriageSection section;
  final SearchTriage value;
  final ValueChanged<SearchTriage> onChanged;

  static const _gap = SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      SearchTriageSection.metadata => _metadata(),
      SearchTriageSection.person => _person(),
      SearchTriageSection.history => _history(),
      SearchTriageSection.transportation => _transportation(),
      SearchTriageSection.lastSeen => _lastSeen(),
      SearchTriageSection.physicalDescription => _physicalDescription(),
      SearchTriageSection.clothingAndSupplies => _clothingAndSupplies(),
      SearchTriageSection.healthAndBehavior => _healthAndBehavior(),
      SearchTriageSection.experienceAndResistance =>
        _experienceAndResistance(),
      SearchTriageSection.previousActions => _previousActions(),
    };
  }

  Widget _metadata() {
    final data = value.metadata;
    return _column([
      _field(
        label: 'Número do formulário',
        value: data.formNumber,
        onChanged: (text) => onChanged(
          value.copyWith(metadata: data.copyWith(formNumber: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Data do fato',
        value: data.factDate,
        keyboardType: TextInputType.number,
        inputFormatters: const [DateDigitsInputFormatter()],
        hintText: 'DD/MM/AAAA',
        validator: validateDateInput,
        onChanged: (text) => onChanged(
          value.copyWith(metadata: data.copyWith(factDate: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Hora do fato',
        value: data.factTime,
        keyboardType: TextInputType.number,
        inputFormatters: const [TimeDigitsInputFormatter()],
        hintText: 'HH:MM',
        validator: validateTimeInput,
        onChanged: (text) => onChanged(
          value.copyWith(metadata: data.copyWith(factTime: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Data do aviso',
        value: data.noticeDate,
        keyboardType: TextInputType.number,
        inputFormatters: const [DateDigitsInputFormatter()],
        hintText: 'DD/MM/AAAA',
        validator: validateDateInput,
        onChanged: (text) => onChanged(
          value.copyWith(metadata: data.copyWith(noticeDate: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Hora do aviso',
        value: data.noticeTime,
        keyboardType: TextInputType.number,
        inputFormatters: const [TimeDigitsInputFormatter()],
        hintText: 'HH:MM',
        validator: validateTimeInput,
        onChanged: (text) => onChanged(
          value.copyWith(metadata: data.copyWith(noticeTime: text)),
        ),
      ),
    ]);
  }

  Widget _person() {
    final person = value.person;
    return _column([
      _field(
        label: 'Nome da pessoa',
        value: person.name,
        onChanged: (text) => onChanged(
          value.copyWith(person: person.copyWith(name: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Apelido',
        value: person.nickname,
        onChanged: (text) => onChanged(
          value.copyWith(person: person.copyWith(nickname: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Endereço',
        value: person.address,
        onChanged: (text) => onChanged(
          value.copyWith(person: person.copyWith(address: text)),
        ),
        minLines: 2,
      ),
      _gap,
      _field(
        label: 'Contato de referência',
        value: person.referenceContact,
        onChanged: (text) => onChanged(
          value.copyWith(person: person.copyWith(referenceContact: text)),
        ),
      ),
      _gap,
      EditableStringList(
        key: const ValueKey('triage-person-contacts'),
        title: 'Outros contatos',
        addLabel: 'Adicionar contato',
        values: person.contacts,
        onChanged: (items) => onChanged(
          value.copyWith(person: person.copyWith(contacts: items)),
        ),
      ),
      _gap,
      EditableStringList(
        key: const ValueKey('triage-person-addresses'),
        title: 'Outros endereços',
        addLabel: 'Adicionar endereço',
        values: person.additionalAddresses,
        minLines: 2,
        onChanged: (items) => onChanged(
          value.copyWith(
            person: person.copyWith(additionalAddresses: items),
          ),
        ),
      ),
      _gap,
      RelatedPeopleEditor(
        value: value.relatedPeople,
        onChanged: (people) => onChanged(
          value.copyWith(relatedPeople: people),
        ),
      ),
    ]);
  }

  Widget _history() {
    final history = value.historyAndDestination;
    return _column([
      _field(
        label: 'Histórico / motivação',
        value: history.narrative,
        minLines: 4,
        onChanged: (text) => onChanged(
          value.copyWith(
            historyAndDestination: history.copyWith(narrative: text),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'A motivação ou situação já ocorreu anteriormente?',
        state: history.recurringMotivation,
        onChanged: (state) => onChanged(
          value.copyWith(
            historyAndDestination:
                history.copyWith(recurringMotivation: state),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Destino pretendido / possível destino',
        value: history.intendedDestination,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(
            historyAndDestination:
                history.copyWith(intendedDestination: text),
          ),
        ),
      ),
    ]);
  }

  Widget _transportation() {
    final transport = value.transportation;
    return _column([
      _triState(
        label: 'Saiu a pé?',
        state: transport.onFoot,
        onChanged: (state) => onChanged(
          value.copyWith(transportation: transport.copyWith(onFoot: state)),
        ),
      ),
      _gap,
      _triState(
        label: 'Utilizou bicicleta?',
        state: transport.bicycle,
        onChanged: (state) => onChanged(
          value.copyWith(transportation: transport.copyWith(bicycle: state)),
        ),
      ),
      if (transport.bicycle == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Bicicleta - marca/modelo',
          value: transport.bicycleMakeModel,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(bicycleMakeModel: text),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Bicicleta - cor',
          value: transport.bicycleColor,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(bicycleColor: text),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Bicicleta - tamanho',
          value: transport.bicycleSize,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(bicycleSize: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Utilizou veículo motorizado?',
        state: transport.motorVehicle,
        onChanged: (state) => onChanged(
          value.copyWith(
            transportation: transport.copyWith(motorVehicle: state),
          ),
        ),
      ),
      if (transport.motorVehicle == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Veículo - tipo',
          value: transport.motorVehicleType,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(motorVehicleType: text),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Veículo - marca/modelo',
          value: transport.motorVehicleMakeModel,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation:
                  transport.copyWith(motorVehicleMakeModel: text),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Veículo - cor',
          value: transport.motorVehicleColor,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(motorVehicleColor: text),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Veículo - placa',
          value: transport.motorVehiclePlate,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(motorVehiclePlate: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Utilizou montaria?',
        state: transport.mount,
        onChanged: (state) => onChanged(
          value.copyWith(transportation: transport.copyWith(mount: state)),
        ),
      ),
      if (transport.mount == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Montaria - tipo',
          value: transport.mountType,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(mountType: text),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Montaria - cor',
          value: transport.mountColor,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation: transport.copyWith(mountColor: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Veículo ou montaria foi localizado?',
        state: transport.vehicleOrMountFound,
        onChanged: (state) => onChanged(
          value.copyWith(
            transportation:
                transport.copyWith(vehicleOrMountFound: state),
          ),
        ),
      ),
      if (transport.vehicleOrMountFound == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes da localização',
          value: transport.vehicleOrMountFoundDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation:
                  transport.copyWith(vehicleOrMountFoundDetails: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'A montaria retornou?',
        state: transport.mountReturned,
        onChanged: (state) => onChanged(
          value.copyWith(
            transportation: transport.copyWith(mountReturned: state),
          ),
        ),
      ),
      if (transport.mountReturned == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes do retorno da montaria',
          value: transport.mountReturnDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              transportation:
                  transport.copyWith(mountReturnDetails: text),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _lastSeen() {
    final lastSeen = value.lastSeen;
    return _column([
      _field(
        label: 'Quando foi visto pela última vez?',
        value: lastSeen.when,
        onChanged: (text) => onChanged(
          value.copyWith(lastSeen: lastSeen.copyWith(when: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Onde foi visto pela última vez?',
        value: lastSeen.where,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(lastSeen: lastSeen.copyWith(where: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Direção / destino indicado no último avistamento',
        value: lastSeen.intendedDirection,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(
            lastSeen: lastSeen.copyWith(intendedDirection: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Nome da testemunha',
        value: lastSeen.witnessName,
        onChanged: (text) => onChanged(
          value.copyWith(lastSeen: lastSeen.copyWith(witnessName: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Endereço da testemunha',
        value: lastSeen.witnessAddress,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(lastSeen: lastSeen.copyWith(witnessAddress: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Contato da testemunha',
        value: lastSeen.witnessContact,
        onChanged: (text) => onChanged(
          value.copyWith(lastSeen: lastSeen.copyWith(witnessContact: text)),
        ),
      ),
      _gap,
      _field(
        label: 'Observações do último avistamento',
        value: lastSeen.notes,
        minLines: 3,
        onChanged: (text) => onChanged(
          value.copyWith(lastSeen: lastSeen.copyWith(notes: text)),
        ),
      ),
    ]);
  }

  Widget _physicalDescription() {
    final physical = value.physicalDescription;
    return _column([
      _field(
        label: 'Idade',
        value: physical.age,
        onChanged: (text) => onChanged(
          value.copyWith(
            physicalDescription: physical.copyWith(age: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Cor / característica de pele',
        value: physical.color,
        onChanged: (text) => onChanged(
          value.copyWith(
            physicalDescription: physical.copyWith(color: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Altura',
        value: physical.height,
        onChanged: (text) => onChanged(
          value.copyWith(
            physicalDescription: physical.copyWith(height: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Cabelos',
        value: physical.hair,
        onChanged: (text) => onChanged(
          value.copyWith(
            physicalDescription: physical.copyWith(hair: text),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'Possui barba?',
        state: physical.beard,
        onChanged: (state) => onChanged(
          value.copyWith(
            physicalDescription: physical.copyWith(beard: state),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Outras características físicas',
        value: physical.notes,
        minLines: 3,
        onChanged: (text) => onChanged(
          value.copyWith(
            physicalDescription: physical.copyWith(notes: text),
          ),
        ),
      ),
    ]);
  }

  Widget _clothingAndSupplies() {
    final clothing = value.clothingAndAccessories;
    final supplies = value.personalSupplies;
    return _column([
      ClothingItemsEditor(
        value: clothing.items,
        onChanged: (items) => onChanged(
          value.copyWith(
            clothingAndAccessories: clothing.copyWith(items: items),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Observações sobre vestimentas e acessórios',
        value: clothing.notes,
        minLines: 3,
        onChanged: (text) => onChanged(
          value.copyWith(
            clothingAndAccessories: clothing.copyWith(notes: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Materiais, equipamentos e suprimentos pessoais',
        value: supplies.notes,
        minLines: 4,
        onChanged: (text) => onChanged(
          value.copyWith(
            personalSupplies: supplies.copyWith(notes: text),
          ),
        ),
      ),
    ]);
  }

  Widget _healthAndBehavior() {
    final health = value.healthAndBehavior;
    return _column([
      _field(
        label: 'Condição geral de saúde',
        value: health.generalCondition,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(generalCondition: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Deficiências físicas',
        value: health.physicalDisabilities,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(physicalDisabilities: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Doenças / condições conhecidas',
        value: health.diseases,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(diseases: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Questões psicológicas / comportamentais informadas',
        value: health.psychologicalIssues,
        minLines: 3,
        onChanged: (text) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(psychologicalIssues: text),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'Faz uso de medicamento?',
        state: health.medicationUse,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(medicationUse: state),
          ),
        ),
      ),
      if (health.medicationUse == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Medicamentos / detalhes',
          value: health.medicationDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              healthAndBehavior: health.copyWith(medicationDetails: text),
            ),
          ),
        ),
        _gap,
        _triState(
          label: 'Tomou a medicação?',
          state: health.tookMedication,
          onChanged: (state) => onChanged(
            value.copyWith(
              healthAndBehavior: health.copyWith(tookMedication: state),
            ),
          ),
        ),
        _gap,
        _field(
          label: 'Consequências da falta do medicamento',
          value: health.lackOfMedicationConsequences,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              healthAndBehavior:
                  health.copyWith(lackOfMedicationConsequences: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Há informação sobre uso de drogas?',
        state: health.drugUse,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(drugUse: state),
          ),
        ),
      ),
      if (health.drugUse == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes sobre uso de drogas',
          value: health.drugDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              healthAndBehavior: health.copyWith(drugDetails: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Há informação sobre conflitos familiares?',
        state: health.familyConflicts,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(familyConflicts: state),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'Há informação sobre conflito no trabalho?',
        state: health.workConflict,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(workConflict: state),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'Há informação sobre problemas financeiros?',
        state: health.financialProblems,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(financialProblems: state),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'Há tentativa anterior de autoagressão informada?',
        state: health.previousSelfHarmAttempt,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior:
                health.copyWith(previousSelfHarmAttempt: state),
          ),
        ),
      ),
      if (health.previousSelfHarmAttempt == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes da tentativa anterior',
          value: health.previousSelfHarmDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              healthAndBehavior:
                  health.copyWith(previousSelfHarmDetails: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Há ameaça anterior de autoagressão informada?',
        state: health.previousSelfHarmThreat,
        onChanged: (state) => onChanged(
          value.copyWith(
            healthAndBehavior:
                health.copyWith(previousSelfHarmThreat: state),
          ),
        ),
      ),
      if (health.previousSelfHarmThreat == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes da ameaça anterior',
          value: health.previousSelfHarmThreatDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              healthAndBehavior:
                  health.copyWith(previousSelfHarmThreatDetails: text),
            ),
          ),
        ),
      ],
      _gap,
      _field(
        label: 'Outras observações de saúde e comportamento',
        value: health.notes,
        minLines: 3,
        onChanged: (text) => onChanged(
          value.copyWith(
            healthAndBehavior: health.copyWith(notes: text),
          ),
        ),
      ),
    ]);
  }

  Widget _experienceAndResistance() {
    final experience = value.experienceAndResistance;
    return _column([
      _triState(
        label: 'Possui experiência em caminhada / área rural?',
        state: experience.ruralWalking,
        onChanged: (state) => onChanged(
          value.copyWith(
            experienceAndResistance:
                experience.copyWith(ruralWalking: state),
          ),
        ),
      ),
      if (experience.ruralWalking == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes da experiência',
          value: experience.ruralWalkingDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              experienceAndResistance:
                  experience.copyWith(ruralWalkingDetails: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Conhece a área?',
        state: experience.knowsArea,
        onChanged: (state) => onChanged(
          value.copyWith(
            experienceAndResistance: experience.copyWith(knowsArea: state),
          ),
        ),
      ),
      if (experience.knowsArea == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Desde quando / nível de conhecimento da área',
          value: experience.knowsAreaSince,
          onChanged: (text) => onChanged(
            value.copyWith(
              experienceAndResistance:
                  experience.copyWith(knowsAreaSince: text),
            ),
          ),
        ),
      ],
      _gap,
      _triState(
        label: 'Já se perdeu anteriormente?',
        state: experience.previouslyLost,
        onChanged: (state) => onChanged(
          value.copyWith(
            experienceAndResistance:
                experience.copyWith(previouslyLost: state),
          ),
        ),
      ),
      if (experience.previouslyLost == AnswerState.yes) ...[
        _gap,
        _field(
          label: 'Detalhes de ocorrência anterior',
          value: experience.previousLostDetails,
          minLines: 2,
          onChanged: (text) => onChanged(
            value.copyWith(
              experienceAndResistance:
                  experience.copyWith(previousLostDetails: text),
            ),
          ),
        ),
      ],
      _gap,
      _field(
        label: 'Resistência / condicionamento físico informado',
        value: experience.physicalResistance,
        minLines: 2,
        onChanged: (text) => onChanged(
          value.copyWith(
            experienceAndResistance:
                experience.copyWith(physicalResistance: text),
          ),
        ),
      ),
      _gap,
      _triState(
        label: 'Sabe nadar?',
        state: experience.canSwim,
        onChanged: (state) => onChanged(
          value.copyWith(
            experienceAndResistance: experience.copyWith(canSwim: state),
          ),
        ),
      ),
    ]);
  }

  Widget _previousActions() {
    final previous = value.previousActions;
    return _field(
      label: 'Procedimentos / medidas já realizados e respectivos resultados',
      value: previous.description,
      minLines: 7,
      onChanged: (text) => onChanged(
        value.copyWith(
          previousActions: previous.copyWith(description: text),
        ),
      ),
    );
  }

  Widget _column(List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );

  Widget _field({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int minLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    FormFieldValidator<String>? validator,
  }) =>
      TextFormField(
        initialValue: value,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : null,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        autovalidateMode: validator == null
            ? AutovalidateMode.disabled
            : AutovalidateMode.onUserInteraction,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          alignLabelWithHint: minLines > 1,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _triState({
    required String label,
    required AnswerState state,
    required ValueChanged<AnswerState> onChanged,
  }) =>
      DropdownButtonFormField<AnswerState>(
        initialValue: state,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(
            value: AnswerState.unknown,
            child: Text('Não informado'),
          ),
          DropdownMenuItem(
            value: AnswerState.yes,
            child: Text('Sim'),
          ),
          DropdownMenuItem(
            value: AnswerState.no,
            child: Text('Não'),
          ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      );
}

class EditableStringList extends StatefulWidget {
  const EditableStringList({
    super.key,
    required this.title,
    required this.addLabel,
    required this.values,
    required this.onChanged,
    this.minLines = 1,
  });

  final String title;
  final String addLabel;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final int minLines;

  @override
  State<EditableStringList> createState() => _EditableStringListState();
}

class _EditableStringListState extends State<EditableStringList> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.values
        .map((value) => TextEditingController(text: value))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      _controllers.map((controller) => controller.text).toList(),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          ..._controllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          minLines: widget.minLines,
                          maxLines: widget.minLines == 1 ? 1 : null,
                          onChanged: (_) => _emit(),
                          decoration: InputDecoration(
                            labelText: '${widget.title} ${entry.key + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover',
                        onPressed: () {
                          final removed = _controllers.removeAt(entry.key);
                          removed.dispose();
                          setState(() {});
                          _emit();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: () {
              setState(() => _controllers.add(TextEditingController()));
              _emit();
            },
            icon: const Icon(Icons.add),
            label: Text(widget.addLabel),
          ),
        ],
      );
}

class RelatedPeopleEditor extends StatefulWidget {
  const RelatedPeopleEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final List<RelatedPerson> value;
  final ValueChanged<List<RelatedPerson>> onChanged;

  @override
  State<RelatedPeopleEditor> createState() => _RelatedPeopleEditorState();
}

class _RelatedPeopleEditorState extends State<RelatedPeopleEditor> {
  late final List<_RelatedPersonControllers> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.value.map(_RelatedPersonControllers.fromModel).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
        _items.map((item) => item.toModel()).toList(growable: false),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Familiares, amigos e pessoas relacionadas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ..._items.asMap().entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: entry.value.relation,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Relação / vínculo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: entry.value.name,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: entry.value.contact,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Contato',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final removed = _items.removeAt(entry.key);
                              removed.dispose();
                              setState(() {});
                          _emit();
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remover'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: () {
              setState(() => _items.add(_RelatedPersonControllers.empty()));
              _emit();
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Adicionar pessoa relacionada'),
          ),
        ],
      );
}

class _RelatedPersonControllers {
  _RelatedPersonControllers({
    required this.relation,
    required this.name,
    required this.contact,
  });

  factory _RelatedPersonControllers.fromModel(RelatedPerson value) =>
      _RelatedPersonControllers(
        relation: TextEditingController(text: value.relation),
        name: TextEditingController(text: value.name),
        contact: TextEditingController(text: value.contact),
      );

  factory _RelatedPersonControllers.empty() =>
      _RelatedPersonControllers.fromModel(
        const RelatedPerson(relation: '', name: '', contact: ''),
      );

  final TextEditingController relation;
  final TextEditingController name;
  final TextEditingController contact;

  RelatedPerson toModel() => RelatedPerson(
        relation: relation.text,
        name: name.text,
        contact: contact.text,
      );

  void dispose() {
    relation.dispose();
    name.dispose();
    contact.dispose();
  }
}

class ClothingItemsEditor extends StatefulWidget {
  const ClothingItemsEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final List<ClothingItem> value;
  final ValueChanged<List<ClothingItem>> onChanged;

  @override
  State<ClothingItemsEditor> createState() => _ClothingItemsEditorState();
}

class _ClothingItemsEditorState extends State<ClothingItemsEditor> {
  late final List<_ClothingItemControllers> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.value.map(_ClothingItemControllers.fromModel).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
        _items.map((item) => item.toModel()).toList(growable: false),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vestimentas e acessórios',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ..._items.asMap().entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _controllerField(entry.value.item, 'Item', _emit),
                        const SizedBox(height: 8),
                        _controllerField(entry.value.type, 'Tipo', _emit),
                        const SizedBox(height: 8),
                        _controllerField(entry.value.color, 'Cor', _emit),
                        const SizedBox(height: 8),
                        _controllerField(
                          entry.value.materialOrPattern,
                          'Material / estampa',
                          _emit,
                        ),
                        const SizedBox(height: 8),
                        _controllerField(entry.value.size, 'Tamanho', _emit),
                        const SizedBox(height: 8),
                        _controllerField(entry.value.model, 'Modelo', _emit),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              final removed = _items.removeAt(entry.key);
                              removed.dispose();
                              setState(() {});
                          _emit();
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remover'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: () {
              setState(() => _items.add(_ClothingItemControllers.empty()));
              _emit();
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar vestimenta ou acessório'),
          ),
        ],
      );

  Widget _controllerField(
    TextEditingController controller,
    String label,
    VoidCallback onChanged,
  ) =>
      TextFormField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}

class _ClothingItemControllers {
  _ClothingItemControllers({
    required this.item,
    required this.type,
    required this.color,
    required this.materialOrPattern,
    required this.size,
    required this.model,
  });

  factory _ClothingItemControllers.fromModel(ClothingItem value) =>
      _ClothingItemControllers(
        item: TextEditingController(text: value.item),
        type: TextEditingController(text: value.type),
        color: TextEditingController(text: value.color),
        materialOrPattern:
            TextEditingController(text: value.materialOrPattern),
        size: TextEditingController(text: value.size),
        model: TextEditingController(text: value.model),
      );

  factory _ClothingItemControllers.empty() =>
      _ClothingItemControllers.fromModel(
        const ClothingItem(
          item: '',
          type: '',
          color: '',
          materialOrPattern: '',
          size: '',
          model: '',
        ),
      );

  final TextEditingController item;
  final TextEditingController type;
  final TextEditingController color;
  final TextEditingController materialOrPattern;
  final TextEditingController size;
  final TextEditingController model;

  ClothingItem toModel() => ClothingItem(
        item: item.text,
        type: type.text,
        color: color.text,
        materialOrPattern: materialOrPattern.text,
        size: size.text,
        model: model.text,
      );

  void dispose() {
    item.dispose();
    type.dispose();
    color.dispose();
    materialOrPattern.dispose();
    size.dispose();
    model.dispose();
  }
}
