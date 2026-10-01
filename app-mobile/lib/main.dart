import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'report_model.dart';
import 'report_pdf.dart';
import 'report_store.dart';
import 'report_sync.dart';

void main() => runApp(const GrupoSucuaranaApp());

class GrupoSucuaranaApp extends StatelessWidget {
  const GrupoSucuaranaApp({super.key, this.reportRepository});

  final ReportRepository? reportRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Grupo Suçuarana',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: HomePage(reportRepository: reportRepository),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.reportRepository});

  final ReportRepository? reportRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ReportRepository _store;
  final _syncService = ReportSync();
  List<Report> _reports = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _store = widget.reportRepository ?? ReportStore();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final reports = await _store.load();
      final sortedReports = [...reports]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (!mounted) return;
      setState(() {
        _reports = sortedReports;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Não foi possível carregar os relatórios salvos.';
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _reload();
  }

  Future<void> _edit([Report? report]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReportFormPage(
          report: report,
          reportRepository: _store,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _sync() async {
    final pending = _reports
        .where((item) => item.syncStatus == SyncStatus.pending)
        .toList();
    var synced = 0;
    for (final report in pending) {
      try {
        await _syncService.send(report);
        final index = _reports.indexWhere((item) => item.id == report.id);
        if (index >= 0) {
          setState(() {
            _reports = [..._reports]
              ..[index] = report.copyWith(syncStatus: SyncStatus.synced);
          });
        }
        synced++;
      } on DioException catch (error) {
        if (mounted) {
          _message(
            'Não foi possível sincronizar. API indisponível '
            '(${error.response?.statusCode ?? 'sem conexão'}).',
          );
        }
        break;
      } catch (_) {
        if (mounted) _message('Não foi possível sincronizar este relatório.');
        break;
      }
    }
    await _store.save(_reports);
    if (mounted && synced > 0) {
      _message('$synced relatório(s) sincronizado(s) com a API.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Grupo Suçuarana'),
          actions: [
            if (_reports.any(
              (item) => item.syncStatus == SyncStatus.pending,
            ))
              IconButton(
                onPressed: _sync,
                tooltip: 'Sincronizar',
                icon: const Icon(Icons.cloud_upload_outlined),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.add),
          label: const Text('Novo relatório'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56),
                          const SizedBox(height: 12),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _retryLoad,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _reports.isEmpty
                    ? _EmptyState(onCreate: _edit)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          Text(
                            'Relatórios de operação',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${_reports.length} relatório(s) salvo(s) '
                            'no dispositivo',
                          ),
                          const SizedBox(height: 12),
                          ..._reports.map(
                            (report) => Card(
                              child: ListTile(
                                onTap: () => _edit(report),
                                leading: CircleAvatar(
                                  child: Icon(
                                    report.syncStatus == SyncStatus.synced
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                  ),
                                ),
                                title: Text(
                                  report.title.isEmpty
                                      ? 'Relatório sem título'
                                      : report.title,
                                ),
                                subtitle: Text(_reportSubtitle(report)),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            ),
                          ),
                        ],
                      ),
      );

  String _reportSubtitle(Report report) {
    final lifecycle = report.lifecycle == ReportLifecycle.draft
        ? 'Rascunho • '
        : '';
    final location =
        report.location.isEmpty ? 'Local não informado' : report.location;
    return '$lifecycle$location • ${_date(report.updatedAt)}';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 72),
              const SizedBox(height: 16),
              Text(
                'Nenhum relatório ainda',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Crie um relatório. Ele ficará salvo offline neste dispositivo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Criar relatório'),
              ),
            ],
          ),
        ),
      );
}

class ReportFormPage extends StatefulWidget {
  const ReportFormPage({
    super.key,
    this.report,
    this.reportRepository,
  });

  final Report? report;
  final ReportRepository? reportRepository;

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage>
    with WidgetsBindingObserver {
  static const _autosaveDelay = Duration(milliseconds: 700);
  static const _lastStep = 6;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _controllers = <String, TextEditingController>{};
  final _teams = <TextEditingController>[];
  final _resources = <TextEditingController>[];
  final _attachments = <String>[];

  late final ReportRepository _store;
  late final String _reportId;
  late final DateTime _createdAt;
  late DateTime _date;
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
    'missingName': 'Nome ou referência do desaparecido',
    'lastSeen': 'Último avistamento',
    'contact': 'Contato de referência',
    'location': 'Local da operação',
    'start': 'Início',
    'end': 'Término',
    'physical': 'Descrição física',
    'clothing': 'Vestimentas',
    'health': 'Saúde e necessidades',
    'procedures': 'Procedimentos realizados',
    'conclusion': 'Conclusão e próximos passos',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final report = widget.report;
    _store = widget.reportRepository ?? ReportStore();
    _reportId = report?.id ?? const Uuid().v4();
    _createdAt = report?.createdAt ?? DateTime.now();
    _date = report?.identification.date ?? DateTime.now();
    _lifecycle = report?.lifecycle ?? ReportLifecycle.draft;
    _syncStatus = report?.syncStatus ?? SyncStatus.pending;
    _hasSaved = report != null;

    final restoredStep = report?.lastEditedStep ?? 0;
    _step = restoredStep < 0
        ? 0
        : restoredStep > _lastStep
            ? _lastStep
            : restoredStep;

    final values = {
      'title': report?.identification.title,
      'coordinator': report?.identification.coordinator,
      'missingName': report?.missing.name,
      'lastSeen': report?.missing.lastSeen,
      'contact': report?.missing.contact,
      'location': report?.operation.location,
      'start': report?.operation.start,
      'end': report?.operation.end,
      'physical': report?.physicalDescription,
      'clothing': report?.clothing,
      'health': report?.health,
      'procedures': report?.procedures,
      'conclusion': report?.conclusion,
    };

    for (final entry in values.entries) {
      _controllers[entry.key] = _trackedController(entry.value ?? '');
    }
    for (final value in report?.teams ?? const <String>[]) {
      _teams.add(_trackedController(value));
    }
    for (final value in report?.resources ?? const <String>[]) {
      _resources.add(_trackedController(value));
    }
    _attachments.addAll(report?.attachments ?? const <String>[]);
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
    for (final controller in [..._teams, ..._resources]) {
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
        missing: MissingPerson(
          name: _text('missingName'),
          lastSeen: _text('lastSeen'),
          contact: _text('contact'),
        ),
        operation: Operation(
          location: _text('location'),
          start: _text('start'),
          end: _text('end'),
        ),
        physicalDescription: _text('physical'),
        clothing: _text('clothing'),
        health: _text('health'),
        procedures: _text('procedures'),
        teams: _values(_teams),
        resources: _values(_resources),
        conclusion: _text('conclusion'),
        attachments: List.unmodifiable(_attachments),
        createdAt: _createdAt,
        updatedAt: DateTime.now(),
        lifecycle: lifecycle ?? _lifecycle,
        lastEditedStep: _step,
        syncStatus: _syncStatus,
      );

  Future<void> _saveFinal() async {
    if (!_formKey.currentState!.validate()) return;

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

  Future<void> _attach() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(
          () => _attachments.add(kIsWeb ? image.name : image.path),
        );
        _scheduleAutosave(contentChanged: true);
      }
    } on UnsupportedError {
      if (mounted) _message('Anexos não são suportados neste ambiente.');
    } catch (_) {
      if (mounted) _message('Não foi possível selecionar o anexo.');
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
    _scheduleAutosave(contentChanged: true);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _text(String key) => _controllers[key]!.text.trim();

  List<String> _values(List<TextEditingController> values) => values
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  TextFormField _input(
    String key, {
    int minLines = 1,
    bool required = false,
  }) =>
      TextFormField(
        controller: _controllers[key],
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 5,
        decoration: InputDecoration(
          labelText: _fields[key],
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'Preencha este campo'
                : null
            : null,
      );

  Widget _repeatable(
    String label,
    List<TextEditingController> values,
    IconData icon,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          ...values.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: '$label ${entry.key + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final removed = values.removeAt(entry.key);
                          setState(removed.dispose);
                          _scheduleAutosave(contentChanged: true);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: () => setState(
              () => values.add(_trackedController()),
            ),
            icon: Icon(icon),
            label: Text('Adicionar $label'),
          ),
        ],
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

  List<Step> _steps() => [
        Step(
          title: const Text('Identificação'),
          isActive: _step >= 0,
          content: Column(
            children: [
              _input('title', required: true),
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
        ),
        Step(
          title: const Text('Desaparecido'),
          isActive: _step >= 1,
          content: Column(
            children: [
              _input('missingName'),
              const SizedBox(height: 12),
              _input('lastSeen'),
              const SizedBox(height: 12),
              _input('contact'),
            ],
          ),
        ),
        Step(
          title: const Text('Operação'),
          isActive: _step >= 2,
          content: Column(
            children: [
              _input('location', required: true),
              const SizedBox(height: 12),
              _input('start'),
              const SizedBox(height: 12),
              _input('end'),
            ],
          ),
        ),
        Step(
          title: const Text('Descrição física'),
          isActive: _step >= 3,
          content: _input('physical', minLines: 3),
        ),
        Step(
          title: const Text('Vestimentas e saúde'),
          isActive: _step >= 4,
          content: Column(
            children: [
              _input('clothing', minLines: 3),
              const SizedBox(height: 12),
              _input('health', minLines: 3),
            ],
          ),
        ),
        Step(
          title: const Text('Procedimentos e equipes'),
          isActive: _step >= 5,
          content: Column(
            children: [
              _input('procedures', minLines: 3),
              const SizedBox(height: 16),
              _repeatable('Equipe', _teams, Icons.group_add),
              const SizedBox(height: 8),
              _repeatable(
                'Recurso',
                _resources,
                Icons.inventory_2_outlined,
              ),
            ],
          ),
        ),
        Step(
          title: const Text('Conclusão e anexos'),
          isActive: _step >= 6,
          content: Column(
            children: [
              _input('conclusion', minLines: 3),
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
                    (entry) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.image_outlined),
                      title: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        onPressed: () => _removeAttachment(entry.key),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ];

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
                onPressed: () => exportReportPdf(_snapshot()),
                tooltip: 'Exportar PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
          ],
        ),
        body: Column(
          children: [
            _saveIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _step,
                  onStepContinue: () {
                    if (_step < _steps().length - 1) {
                      _goToStep(_step + 1);
                    } else {
                      unawaited(_saveFinal());
                    }
                  },
                  onStepCancel: () {
                    if (_step > 0) {
                      _goToStep(_step - 1);
                    } else {
                      unawaited(_leaveForm());
                    }
                  },
                  onStepTapped: _goToStep,
                  steps: _steps(),
                  controlsBuilder: (context, details) => Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            _step == _steps().length - 1
                                ? 'Salvar offline'
                                : 'Próximo',
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(_step == 0 ? 'Cancelar' : 'Voltar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String _date(DateTime date) => _dateLabel(date);
