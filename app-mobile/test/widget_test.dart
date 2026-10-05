import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/operational_report.dart';
import 'package:grupo_sucuarana_app/main.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_store.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  testWidgets('exibe a tela inicial após carregar relatórios', (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      GrupoSucuaranaApp(reportRepository: repository),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeNext(const <Report>[]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Grupo Suçuarana'), findsOneWidget);
    expect(find.text('Novo relatório'), findsOneWidget);
    expect(find.text('Nenhum relatório ainda'), findsOneWidget);
  });

  testWidgets('mostra erro e permite tentar carregar novamente', (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      GrupoSucuaranaApp(reportRepository: repository),
    );

    repository.failNext(StateError('falha simulada'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text('Não foi possível carregar os relatórios salvos.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeNext(const <Report>[]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Nenhum relatório ainda'), findsOneWidget);
  });

  testWidgets('ordena uma lista imutável sem modificar a origem', (tester) async {
    final repository = _FakeReportRepository();
    final older = _fakeReport(
      id: 'older',
      title: 'Relatório antigo',
      updatedAt: DateTime.utc(2026, 9, 30),
    );
    final newer = _fakeReport(
      id: 'newer',
      title: 'Relatório novo',
      updatedAt: DateTime.utc(2026, 10, 1),
    );
    final reports = List<Report>.unmodifiable([older, newer]);

    await tester.pumpWidget(
      GrupoSucuaranaApp(reportRepository: repository),
    );

    repository.completeNext(reports);
    await tester.pump();
    await tester.pump();

    expect(find.text('Relatório novo'), findsOneWidget);
    expect(find.text('Relatório antigo'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Relatório novo')).dy,
      lessThan(tester.getTopLeft(find.text('Relatório antigo')).dy),
    );
    expect(reports.first.id, 'older');
  });

  testWidgets('navega pelo formulário estruturado', (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(reportRepository: repository),
      ),
    );
    await tester.pump();

    expect(find.text('Identificação'), findsOneWidget);
    expect(find.text('Título do relatório'), findsOneWidget);
    expect(find.text('Próximo'), findsWidgets);
    expect(find.text('Rascunho local'), findsOneWidget);
  });

  testWidgets('salva rascunho automaticamente após edição', (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(reportRepository: repository),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título do relatório'),
      'Rascunho fictício',
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(repository.upserts, isNotEmpty);
    expect(repository.upserts.last.title, 'Rascunho fictício');
    expect(repository.upserts.last.lifecycle, ReportLifecycle.draft);
    expect(find.text('Salvo no dispositivo'), findsOneWidget);
  });

  testWidgets('restaura a seção estável salva de um rascunho', (tester) async {
    final repository = _FakeReportRepository();
    final report = _fakeReport(
      id: 'draft-001',
      title: 'Rascunho recuperado',
      updatedAt: DateTime.utc(2026, 10, 1, 15),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 0,
      lastEditedSection: 'healthAndBehavior',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(
          report: report,
          reportRepository: repository,
        ),
      ),
    );

    expect(find.text('Saúde e comportamento'), findsOneWidget);
    expect(find.text('Etapa 9 de 17'), findsOneWidget);
    expect(find.text('Salvo no dispositivo'), findsOneWidget);
  });

  testWidgets('mapeia posição legada para a nova seção', (tester) async {
    final repository = _FakeReportRepository();
    final report = _fakeReport(
      id: 'legacy-draft-001',
      title: 'Rascunho legado fictício',
      updatedAt: DateTime.utc(2026, 10, 1, 15),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(
          report: report,
          reportRepository: repository,
        ),
      ),
    );

    expect(find.text('Descrição física'), findsOneWidget);
    expect(find.text('Etapa 7 de 17'), findsOneWidget);
  });

  testWidgets('autosave persiste campo estruturado da triagem', (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(reportRepository: repository),
      ),
    );

    await tester.tap(find.text('Próximo'));
    await tester.pump();

    expect(find.text('Dados do formulário'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Número do formulário'),
      'FORM-FICTICIO-001',
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(repository.upserts, isNotEmpty);
    expect(
      repository.upserts.last.searchTriage.metadata.formNumber,
      'FORM-FICTICIO-001',
    );
    expect(repository.upserts.last.lifecycle, ReportLifecycle.draft);
  });

  testWidgets('autosave persiste narrativa operacional estruturada',
      (tester) async {
    final repository = _FakeReportRepository();
    final report = _fakeReport(
      id: 'operational-draft-001',
      title: 'Rascunho operacional fictício',
      updatedAt: DateTime.utc(2026, 10, 5, 12),
      lifecycle: ReportLifecycle.draft,
      lastEditedSection: 'occurrenceNarrative',
      operationalContent: OperationalReportContent.empty,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(
          report: report,
          reportRepository: repository,
        ),
      ),
    );

    expect(find.text('Descrição da ocorrência'), findsOneWidget);
    expect(find.text('Etapa 13 de 17'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição da ocorrência'),
      'Narrativa operacional fictícia.',
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    expect(repository.upserts, isNotEmpty);
    expect(
      repository.upserts.last.operationalContent.occurrenceNarrative,
      'Narrativa operacional fictícia.',
    );
    expect(repository.upserts.last.lifecycle, ReportLifecycle.draft);
  });

  testWidgets('campo condicional preserva conteúdo ao ocultar e reexibir',
      (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormPage(reportRepository: repository),
      ),
    );

    for (var index = 0; index < 4; index++) {
      final next = find.text('Próximo');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
    }

    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Bicicleta - marca/modelo'), findsNothing);

    Finder bicycleSelector() => find.byWidgetPredicate(
          (widget) =>
              widget is DropdownButtonFormField<AnswerState> &&
              widget.decoration.labelText == 'Utilizou bicicleta?',
        );

    var selector =
        tester.widget<DropdownButtonFormField<AnswerState>>(bicycleSelector());
    selector.onChanged!(AnswerState.yes);
    await tester.pump();

    expect(find.text('Bicicleta - marca/modelo'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bicicleta - marca/modelo'),
      'Modelo fictício',
    );
    await tester.pump();

    selector =
        tester.widget<DropdownButtonFormField<AnswerState>>(bicycleSelector());
    selector.onChanged!(AnswerState.no);
    await tester.pump();
    expect(find.text('Bicicleta - marca/modelo'), findsNothing);

    selector =
        tester.widget<DropdownButtonFormField<AnswerState>>(bicycleSelector());
    selector.onChanged!(AnswerState.yes);
    await tester.pump();

    final restored = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Bicicleta - marca/modelo'),
    );
    expect(restored.controller?.text ?? restored.initialValue, 'Modelo fictício');
  });
}

class _FakeReportRepository implements ReportRepository {
  final List<Completer<List<Report>>> _loads = <Completer<List<Report>>>[];
  final List<Report> upserts = <Report>[];

  @override
  Future<List<Report>> load() {
    final completer = Completer<List<Report>>();
    _loads.add(completer);
    return completer.future;
  }

  @override
  Future<void> save(List<Report> reports) async {}

  @override
  Future<void> upsert(Report report) async {
    upserts.add(report);
  }

  void completeNext(List<Report> reports) {
    _pendingLoad.complete(reports);
  }

  void failNext(Object error) {
    _pendingLoad.completeError(error);
  }

  Completer<List<Report>> get _pendingLoad =>
      _loads.firstWhere((completer) => !completer.isCompleted);
}

Report _fakeReport({
  required String id,
  required String title,
  required DateTime updatedAt,
  ReportLifecycle lifecycle = ReportLifecycle.readyForReview,
  int lastEditedStep = 0,
  String? lastEditedSection,
  OperationalReportContent? operationalContent,
}) {
  return Report(
    id: id,
    identification: Identification(
      title: title,
      date: updatedAt,
      coordinator: 'Equipe de teste',
    ),
    missing: const MissingPerson(
      name: 'Pessoa fictícia',
      lastSeen: 'Local fictício',
      contact: 'Contato fictício',
    ),
    operation: const Operation(
      location: 'Cidade fictícia',
      start: '08:00',
      end: '12:00',
    ),
    operationalContent: operationalContent,
    physicalDescription: 'Descrição fictícia.',
    clothing: 'Vestimenta fictícia.',
    health: 'Sem dados reais.',
    procedures: 'Procedimentos de teste.',
    teams: const <String>['Equipe Alpha'],
    resources: const <String>['Recurso de teste'],
    conclusion: 'Conclusão fictícia.',
    attachments: const <String>[],
    createdAt: updatedAt.subtract(const Duration(hours: 1)),
    updatedAt: updatedAt,
    lifecycle: lifecycle,
    lastEditedStep: lastEditedStep,
    lastEditedSection: lastEditedSection,
    syncStatus: SyncStatus.pending,
  );
}
