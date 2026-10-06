import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'attachment_storage.dart';
import 'operational_report.dart';
import 'operational/operational_sections.dart';
import 'report_attachment.dart';
import 'report_model.dart';
import 'report_pdf_preview_page.dart';
import 'report_review_page.dart';
import 'report_store.dart';
import 'search_triage.dart';
import 'structured_input_formatters.dart';
import 'triage/search_triage_sections.dart';

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({
    super.key,
    this.report,
    this.reportRepository,
    this.attachmentStorage,
  });

  final Report? report;
  final ReportRepository? reportRepository;
  final AttachmentStorage? attachmentStorage;

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage>
    with WidgetsBindingObserver {
  static const _autosaveDelay = Duration(milliseconds: 700);

  static const _sections = <_FormSection>[
    _FormSection('identification', 'Identificação'),
    _FormSection(
      'triageMetadata',
      'Dados do formulário',
      SearchTriageSection.metadata,
    ),
    _FormSection(
      'person',
      'Pessoa e contatos',
      SearchTriageSection.person,
    ),
    _FormSection(
      'history',
      'Histórico e destino',
      SearchTriageSection.history,
    ),
    _FormSection(
      'transportation',
      'Transporte',
      SearchTriageSection.transportation,
    ),
    _FormSection(
      'lastSeen',
      'Último avistamento',
      SearchTriageSection.lastSeen,
    ),
    _FormSection(
      'physicalDescription',
      'Descrição física',
      SearchTriageSection.physicalDescription,
    ),
    _FormSection(
      'clothingAndSupplies',
      'Vestimentas e materiais',
      SearchTriageSection.clothingAndSupplies,
    ),
    _FormSection(
      'healthAndBehavior',
      'Saúde e comportamento',
      SearchTriageSection.healthAndBehavior,
    ),
    _FormSection(
      'experienceAndResistance',
      'Experiência e resistência',
      SearchTriageSection.experienceAndResistance,
    ),
    _FormSection(
      'previousActions',
      'Procedimentos anteriores',
      SearchTriageSection.previousActions,
    ),
    _FormSection(
      'generalInformation',
      'Informações gerais do relatório',
      null,
      OperationalSection.generalInformation,
    ),
    _FormSection(
      'occurrenceNarrative',
      'Descrição da ocorrência',
      null,
      OperationalSection.occurrenceNarrative,
    ),
    _FormSection('operation', 'Operação'),
    _FormSection(
      'teamsAndResources',
      'Desenvolvimento e equipes',
      null,
      OperationalSection.developmentAndTeams,
    ),
    _FormSection(
      'resources',
      'Recursos utilizados',
      null,
      OperationalSection.resources,
    ),
    _FormSection(
      'conclusionAndAttachments',
      'Conclusão e anexos',
      null,
      OperationalSection.conclusion,
    ),
  ];

  final _picker = ImagePicker();
  final _controllers = <String, TextEditingController>{};
  final _attachments = <ReportAttachment>[];

  late final ReportRepository _store;
  late final AttachmentStorage _attachmentStorage;
  late final String _reportId;
  late final DateTime _createdAt;
  late DateTime _date;
  late SearchTriage _searchTriage;
  late OperationalReportContent _operationalContent;
  late ReportLifecycle _lifecycle;
  late SyncStatus _syncStatus;

  Timer? _autosaveTimer;
  Future<void>? _saveInFlight;
  int _step = 0;
  int _changeVersion = 0;
  bool _dirty = false;
  bool _saving = false;
  bool _hasSaved = false;
  String? _saveError;

  static const _fields = <String, String>{
    'title': 'Título do relatório',
    'coordinator': 'Coordenação/equipe responsável',
    'location': 'Local da operação',
    'start': 'Início',
    'end': 'Término',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final report = widget.report;
    _store = widget.reportRepository ?? ReportStore();
    _attachmentStorage =
        widget.attachmentStorage ?? LocalAttachmentStorage();
    _reportId = report?.id ?? const Uuid().v4();
    _createdAt = report?.createdAt ?? DateTime.now();
    _date = report?.identification.date ?? DateTime.now();
    _searchTriage = report?.searchTriage ?? SearchTriage.empty;
    _operationalContent =
        report?.operationalContent ?? OperationalReportContent.empty;
    _lifecycle = report?.lifecycle ?? ReportLifecycle.draft;
    _syncStatus = report?.syncStatus ?? SyncStatus.pending;
    _hasSaved = report != null;
    _step = _restoreStep(report);

    final values = {
      'title': report?.identification.title,
      'coordinator': report?.identification.coordinator,
      'location': report?.operation.location,
      'start': report?.operation.start,
      'end': report?.operation.end,
    };

    for (final entry in values.entries) {
      _controllers[entry.key] = _trackedController(entry.value ?? '');
    }
    _attachments.addAll(
      report?.attachmentItems ?? const <ReportAttachment>[],
    );
  }

  int _restoreStep(Report? report) {
    if (report == null) return 0;

    final stableSection = report.lastEditedSection;
    if (stableSection != null) {
      final index = _sections.indexWhere(
        (section) => section.id == stableSection,
      );
      if (index >= 0) return index;
    }

    return switch (report.lastEditedStep) {
      0 => 0,
      1 => 2,
      2 => 13,
      3 => 6,
      4 => 7,
      5 => 10,
      6 => 16,
      _ => 0,
    };
  }

  TextEditingController _trackedController([String text = '']) {
    final controller = TextEditingController(text: text);
    controller.addListener(_onContentChanged);
    return controller;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_dirty &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      unawaited(_persistDraft());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();

    final pendingSnapshot = _dirty ? _snapshot() : null;

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    if (pendingSnapshot != null) {
      unawaited(_store.upsert(pendingSnapshot));
    }

    super.dispose();
  }

  void _onContentChanged() {
    _scheduleAutosave(contentChanged: true);
  }

  void _onTriageChanged(SearchTriage value) {
    setState(() => _searchTriage = value);
    _scheduleAutosave(contentChanged: true);
  }

  void _onOperationalChanged(OperationalReportContent value) {
    setState(() => _operationalContent = value);
    _scheduleAutosave(contentChanged: true);
  }

  void _scheduleAutosave({required bool contentChanged}) {
    if (contentChanged) {
      _lifecycle = ReportLifecycle.draft;
      _syncStatus = SyncStatus.pending;
    }

    _dirty = true;
    _changeVersion++;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(
      _autosaveDelay,
      () => unawaited(_persistDraft()),
    );

    if (mounted && (!_saving || _saveError != null)) {
      setState(() {
        _saving = true;
        _saveError = null;
      });
    }
  }

  Future<bool> _persistDraft() async {
    _autosaveTimer?.cancel();

    while (_dirty) {
      final activeSave = _saveInFlight;
      if (activeSave != null) {
        try {
          await activeSave;
        } catch (_) {
          return false;
        }
        continue;
      }

      final version = _changeVersion;
      final report = _snapshot();
      final save = _store.upsert(report);
      _saveInFlight = save;

      try {
        await save;
        if (version == _changeVersion) {
          _dirty = false;
        }
        if (mounted) {
          setState(() {
            _hasSaved = true;
            _saving = _dirty;
            _saveError = null;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _saving = false;
            _saveError = 'Não foi possível salvar as alterações.';
          });
        }
        return false;
      } finally {
        if (identical(_saveInFlight, save)) {
          _saveInFlight = null;
        }
      }
    }

    return true;
  }

  Report _snapshot({ReportLifecycle? lifecycle}) => Report(
        id: _reportId,
        identification: Identification(
          title: _text('title'),
          date: _date,
          coordinator: _text('coordinator'),
        ),
        searchTriage: _searchTriage,
        operation: Operation(
          location: _text('location'),
          start: _text('start'),
          end: _text('end'),
        ),
        operationalContent: _operationalContent,
        attachmentItems: List.unmodifiable(_attachments),
        createdAt: _createdAt,
        updatedAt: DateTime.now(),
        lifecycle: lifecycle ?? _lifecycle,
        lastEditedStep: _step,
        lastEditedSection: _sections[_step].id,
        syncStatus: _syncStatus,
      );

  Future<void> _reviewReport() async {
    if (_text('title').isEmpty) {
      _goToStep(0);
      _message('Preencha o título do relatório.');
      return;
    }
    if (_text('location').isEmpty) {
      _goToStep(13);
      _message('Preencha o local da operação.');
      return;
    }

    final saved = await _persistDraft();
    if (!saved || !mounted) return;

    final result = await Navigator.of(context).push<ReportReviewResult>(
      MaterialPageRoute(
        builder: (_) => ReportReviewPage(report: _snapshot()),
      ),
    );
    if (!mounted || result == null) return;

    final editSection = result.editSection;
    if (editSection != null) {
      final index = _sections.indexWhere(
        (section) => section.id == editSection,
      );
      if (index >= 0) {
        _goToStep(index);
      }
      return;
    }

    if (result.confirmed) {
      await _saveFinal();
    }
  }

  Future<void> _saveFinal() async {
    _autosaveTimer?.cancel();
    setState(() {
      _lifecycle = ReportLifecycle.readyForReview;
      _syncStatus = SyncStatus.pending;
      _dirty = true;
      _changeVersion++;
      _saving = true;
      _saveError = null;
    });

    final saved = await _persistDraft();
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _leaveForm() async {
    final saved = await _persistDraft();
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _previewPdf() async {
    final saved = await _persistDraft();
    if (!saved || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReportPdfPreviewPage(
          report: _snapshot(),
        ),
      ),
    );
  }

  Future<void> _attach() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final attachment = await _attachmentStorage.persistImage(
        reportId: _reportId,
        originalName: image.name,
        bytes: await image.readAsBytes(),
      );
      if (!mounted) return;

      setState(() => _attachments.add(attachment));
      _scheduleAutosave(contentChanged: true);
    } on UnsupportedError {
      if (mounted) _message('Anexos não são suportados neste ambiente.');
    } catch (_) {
      if (mounted) {
        _message('Não foi possível persistir o anexo no dispositivo.');
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    final removed = _attachments[index];

    setState(() => _attachments.removeAt(index));
    _scheduleAutosave(contentChanged: true);

    final saved = await _persistDraft();
    if (!saved) {
      if (mounted) {
        setState(() => _attachments.insert(index, removed));
        _scheduleAutosave(contentChanged: true);
        _message('Não foi possível remover o anexo com segurança.');
      }
      return;
    }

    try {
      await _attachmentStorage.delete(removed);
    } catch (_) {
      if (mounted) {
        _message(
          'Anexo removido do relatório, mas o arquivo local não pôde ser limpo.',
        );
      }
    }
  }

  void _updateAttachmentCaption(int index, String caption) {
    _attachments[index] = _attachments[index].copyWith(caption: caption);
    _scheduleAutosave(contentChanged: true);
  }

  void _moveAttachment(int from, int to) {
    if (to < 0 || to >= _attachments.length || from == to) return;

    setState(() {
      final item = _attachments.removeAt(from);
      _attachments.insert(to, item);
    });
    _scheduleAutosave(contentChanged: true);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _text(String key) => _controllers[key]!.text.trim();

  TextFormField _input(
    String key, {
    int minLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    FormFieldValidator<String>? validator,
  }) =>
      TextFormField(
        controller: _controllers[key],
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : null,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        autovalidateMode: validator == null
            ? AutovalidateMode.disabled
            : AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: _fields[key],
          hintText: hintText,
          alignLabelWithHint: minLines > 1,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _saveIndicator() {
    final String text;
    final IconData icon;

    if (_saveError != null) {
      text = _saveError!;
      icon = Icons.error_outline;
    } else if (_saving) {
      text = 'Salvando...';
      icon = Icons.sync;
    } else if (_hasSaved) {
      text = 'Salvo no dispositivo';
      icon = Icons.check_circle_outline;
    } else {
      text = 'Rascunho local';
      icon = Icons.edit_note;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _progressHeader() {
    final section = _sections[_step];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etapa ${_step + 1} de ${_sections.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: (_step + 1) / _sections.length),
          const SizedBox(height: 8),
          Text(section.label, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _sectionContent() {
    final section = _sections[_step];
    final triageSection = section.triageSection;
    if (triageSection != null) {
      return SearchTriageSectionView(
        key: ValueKey(section.id),
        section: triageSection,
        value: _searchTriage,
        onChanged: _onTriageChanged,
      );
    }

    final operationalSection = section.operationalSection;
    if (operationalSection != null &&
        section.id != 'conclusionAndAttachments') {
      return OperationalSectionView(
        key: ValueKey(section.id),
        section: operationalSection,
        value: _operationalContent,
        onChanged: _onOperationalChanged,
      );
    }

    return switch (section.id) {
      'identification' => Column(
          children: [
            _input('title'),
            const SizedBox(height: 12),
            _input('coordinator'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data do relatório'),
              subtitle: Text(_dateLabel(_date)),
              trailing: OutlinedButton(
                onPressed: _pickDate,
                child: const Text('Alterar'),
              ),
            ),
          ],
        ),
      'operation' => Column(
          children: [
            _input('location'),
            const SizedBox(height: 12),
            _input(
              'start',
              keyboardType: TextInputType.number,
              inputFormatters: const [TimeDigitsInputFormatter()],
              hintText: 'HH:MM',
              validator: validateTimeInput,
            ),
            const SizedBox(height: 12),
            _input(
              'end',
              keyboardType: TextInputType.number,
              inputFormatters: const [TimeDigitsInputFormatter()],
              hintText: 'HH:MM',
              validator: validateTimeInput,
            ),
          ],
        ),
      'conclusionAndAttachments' => Column(
          children: [
            OperationalSectionView(
              key: const ValueKey('conclusion'),
              section: OperationalSection.conclusion,
              value: _operationalContent,
              onChanged: _onOperationalChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _attach,
                icon: const Icon(Icons.attach_file),
                label: const Text('Adicionar imagem'),
              ),
            ),
            ..._attachments.asMap().entries.map(
                  (entry) => Card(
                    key: ValueKey('attachment-${entry.value.id}'),
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.image_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value.originalName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Mover para cima',
                                onPressed: entry.key == 0
                                    ? null
                                    : () => _moveAttachment(
                                          entry.key,
                                          entry.key - 1,
                                        ),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: 'Mover para baixo',
                                onPressed:
                                    entry.key == _attachments.length - 1
                                        ? null
                                        : () => _moveAttachment(
                                              entry.key,
                                              entry.key + 1,
                                            ),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              IconButton(
                                tooltip: 'Remover anexo',
                                onPressed: () => unawaited(
                                  _removeAttachment(entry.key),
                                ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey(
                              'attachment-caption-${entry.value.id}',
                            ),
                            initialValue: entry.value.caption,
                            minLines: 2,
                            maxLines: null,
                            onChanged: (caption) =>
                                _updateAttachmentCaption(
                                  entry.key,
                                  caption,
                                ),
                            decoration: const InputDecoration(
                              labelText: 'Legenda do anexo',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _controls() => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 28),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  if (_step < _sections.length - 1) {
                    _goToStep(_step + 1);
                  } else {
                    unawaited(_reviewReport());
                  }
                },
                child: Text(
                  _step == _sections.length - 1
                      ? 'Revisar relatório'
                      : 'Próximo',
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                if (_step > 0) {
                  _goToStep(_step - 1);
                } else {
                  unawaited(_leaveForm());
                }
              },
              child: Text(_step == 0 ? 'Sair' : 'Voltar'),
            ),
          ],
        ),
      );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (value != null) {
      setState(() => _date = value);
      _scheduleAutosave(contentChanged: true);
    }
  }

  void _goToStep(int value) {
    setState(() => _step = value);
    _scheduleAutosave(contentChanged: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.report == null ? 'Novo relatório' : 'Editar relatório',
          ),
          actions: [
            if (widget.report != null)
              IconButton(
                onPressed: () => unawaited(_previewPdf()),
                tooltip: 'Visualizar PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
          ],
        ),
        body: Column(
          children: [
            _saveIndicator(),
            _progressHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionContent(),
                    _controls(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _FormSection {
  const _FormSection(
    this.id,
    this.label, [
    this.triageSection,
    this.operationalSection,
  ]);

  final String id;
  final String label;
  final SearchTriageSection? triageSection;
  final OperationalSection? operationalSection;
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';
