import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/main.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_store.dart';

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
    await tester.pumpWidget(const MaterialApp(home: ReportFormPage()));
    await tester.pump();

    expect(find.text('Identificação'), findsOneWidget);
    expect(find.text('Título do relatório'), findsOneWidget);
    expect(find.text('Próximo'), findsWidgets);
  });
}

class _FakeReportRepository implements ReportRepository {
  final List<Completer<List<Report>>> _loads = <Completer<List<Report>>>[];

  @override
  Future<List<Report>> load() {
    final completer = Completer<List<Report>>();
    _loads.add(completer);
    return completer.future;
  }

  @override
  Future<void> save(List<Report> reports) async {}

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
    physicalDescription: 'Descrição fictícia.',
    clothing: 'Vestimenta fictícia.',
    health: 'Sem dados reais.',
    procedures: 'Procedimentos de teste.',
    teams: const <String>['Equipe Alpha'],
    resources: const <String>['Recurso de teste'],
    conclusion: 'Conclusão fictícia.',
    attachments: const <String>[],
    updatedAt: updatedAt,
    syncStatus: SyncStatus.pending,
  );
}
