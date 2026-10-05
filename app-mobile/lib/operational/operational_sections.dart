import 'package:flutter/material.dart';

import '../operational_report.dart';

enum OperationalSection {
  generalInformation,
  occurrenceNarrative,
  developmentAndTeams,
  resources,
  conclusion,
}

class OperationalSectionView extends StatelessWidget {
  const OperationalSectionView({
    super.key,
    required this.section,
    required this.value,
    required this.onChanged,
  });

  final OperationalSection section;
  final OperationalReportContent value;
  final ValueChanged<OperationalReportContent> onChanged;

  static const _gap = SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      OperationalSection.generalInformation => _generalInformation(),
      OperationalSection.occurrenceNarrative => _occurrenceNarrative(),
      OperationalSection.developmentAndTeams => _developmentAndTeams(),
      OperationalSection.resources => _resources(),
      OperationalSection.conclusion => _conclusion(),
    };
  }

  Widget _generalInformation() {
    final info = value.generalInformation;
    return _column([
      _field(
        label: 'Referência externa / boletim',
        value: info.externalReference,
        onChanged: (text) => onChanged(
          value.copyWith(
            generalInformation: info.copyWith(externalReference: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'RG / documento de identidade',
        value: info.documentRg,
        onChanged: (text) => onChanged(
          value.copyWith(
            generalInformation: info.copyWith(documentRg: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'CPF',
        value: info.documentCpf,
        onChanged: (text) => onChanged(
          value.copyWith(
            generalInformation: info.copyWith(documentCpf: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Telefone',
        value: info.phone,
        onChanged: (text) => onChanged(
          value.copyWith(
            generalInformation: info.copyWith(phone: text),
          ),
        ),
      ),
      _gap,
      _field(
        label: 'Contato feito por',
        value: info.contactMadeBy,
        onChanged: (text) => onChanged(
          value.copyWith(
            generalInformation: info.copyWith(contactMadeBy: text),
          ),
        ),
        minLines: 2,
      ),
    ]);
  }

  Widget _occurrenceNarrative() => _field(
        label: 'Descrição da ocorrência',
        value: value.occurrenceNarrative,
        minLines: 8,
        onChanged: (text) => onChanged(
          value.copyWith(occurrenceNarrative: text),
        ),
      );

  Widget _developmentAndTeams() => _column([
        _field(
          label: 'Desenvolvimento do emprego da equipe',
          value: value.developmentNarrative,
          minLines: 8,
          onChanged: (text) => onChanged(
            value.copyWith(developmentNarrative: text),
          ),
        ),
        _gap,
        OperationalTeamsEditor(
          value: value.teams,
          onChanged: (teams) => onChanged(value.copyWith(teams: teams)),
        ),
      ]);

  Widget _resources() => OperationalResourcesEditor(
        value: value.resources,
        onChanged: (resources) => onChanged(
          value.copyWith(resources: resources),
        ),
      );

  Widget _conclusion() => _field(
        label: 'Conclusão',
        value: value.conclusion,
        minLines: 8,
        onChanged: (text) => onChanged(
          value.copyWith(conclusion: text),
        ),
      );

  Widget _column(List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );

  Widget _field({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int minLines = 1,
  }) =>
      TextFormField(
        initialValue: value,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: minLines > 1,
          border: const OutlineInputBorder(),
        ),
      );
}

class OperationalTeamsEditor extends StatefulWidget {
  const OperationalTeamsEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final List<OperationalTeam> value;
  final ValueChanged<List<OperationalTeam>> onChanged;

  @override
  State<OperationalTeamsEditor> createState() => _OperationalTeamsEditorState();
}

class _OperationalTeamsEditorState extends State<OperationalTeamsEditor> {
  late final List<_TeamControllers> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.value.map(_TeamControllers.fromModel).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      _items.map((item) => item.toModel()).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Equipes operacionais',
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
                          controller: entry.value.name,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Nome da equipe / grupo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: entry.value.members,
                          minLines: 3,
                          maxLines: null,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Integrantes (um por linha)',
                            alignLabelWithHint: true,
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
              setState(() => _items.add(_TeamControllers.empty()));
              _emit();
            },
            icon: const Icon(Icons.group_add),
            label: const Text('Adicionar equipe'),
          ),
        ],
      );
}

class _TeamControllers {
  _TeamControllers({
    required this.name,
    required this.members,
  });

  factory _TeamControllers.fromModel(OperationalTeam value) => _TeamControllers(
        name: TextEditingController(text: value.name),
        members: TextEditingController(text: value.members.join('\n')),
      );

  factory _TeamControllers.empty() => _TeamControllers.fromModel(
        const OperationalTeam(name: '', members: <String>[]),
      );

  final TextEditingController name;
  final TextEditingController members;

  OperationalTeam toModel() => OperationalTeam(
        name: name.text,
        members: members.text
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
      );

  void dispose() {
    name.dispose();
    members.dispose();
  }
}

class OperationalResourcesEditor extends StatefulWidget {
  const OperationalResourcesEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final List<OperationalResource> value;
  final ValueChanged<List<OperationalResource>> onChanged;

  @override
  State<OperationalResourcesEditor> createState() =>
      _OperationalResourcesEditorState();
}

class _OperationalResourcesEditorState
    extends State<OperationalResourcesEditor> {
  late final List<_ResourceControllers> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.value.map(_ResourceControllers.fromModel).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      _items.map((item) => item.toModel()).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recursos utilizados',
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
                          controller: entry.value.description,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Recurso / equipamento',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: entry.value.purpose,
                          minLines: 2,
                          maxLines: null,
                          onChanged: (_) => _emit(),
                          decoration: const InputDecoration(
                            labelText: 'Finalidade / uso',
                            alignLabelWithHint: true,
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
              setState(() => _items.add(_ResourceControllers.empty()));
              _emit();
            },
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Adicionar recurso'),
          ),
        ],
      );
}

class _ResourceControllers {
  _ResourceControllers({
    required this.description,
    required this.purpose,
  });

  factory _ResourceControllers.fromModel(OperationalResource value) =>
      _ResourceControllers(
        description: TextEditingController(text: value.description),
        purpose: TextEditingController(text: value.purpose),
      );

  factory _ResourceControllers.empty() => _ResourceControllers.fromModel(
        const OperationalResource(description: '', purpose: ''),
      );

  final TextEditingController description;
  final TextEditingController purpose;

  OperationalResource toModel() => OperationalResource(
        description: description.text,
        purpose: purpose.text,
      );

  void dispose() {
    description.dispose();
    purpose.dispose();
  }
}
