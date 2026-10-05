import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'report_form_page.dart';
import 'report_model.dart';
import 'report_pdf_preview_page.dart';
import 'report_store.dart';
import 'report_sync.dart';

export 'report_form_page.dart';

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

  Future<void> _preview(Report report) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReportPdfPreviewPage(report: report),
      ),
    );
  }

  Future<void> _sync() async {
    final pending = reportsEligibleForSync(_reports);
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
            if (_reports.any(isReportSyncEligible))
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (report.lifecycle !=
                                        ReportLifecycle.draft)
                                      IconButton(
                                        key: ValueKey(
                                          'preview-report-${report.id}',
                                        ),
                                        onPressed: () => _preview(report),
                                        tooltip: 'Visualizar PDF',
                                        icon: const Icon(
                                          Icons.picture_as_pdf_outlined,
                                        ),
                                      ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
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

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';
