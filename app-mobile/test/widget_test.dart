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

    repository.completeLoad(const <Report>[]);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Grupo Suçuarana'), findsOneWidget);
    expect(find.text('Novo relatório'), findsOneWidget);
  });

  testWidgets('mostra erro de carregamento sem ficar preso', (tester) async {
    final repository = _FakeReportRepository();

    await tester.pumpWidget(
      GrupoSucuaranaApp(reportRepository: repository),
    );

    repository.failLoad(StateError('falha simulada'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text('Não foi possível carregar os relatórios salvos.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
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
  final Completer<List<Report>> _loadCompleter = Completer<List<Report>>();

  @override
  Future<List<Report>> load() => _loadCompleter.future;

  @override
  Future<void> save(List<Report> reports) async {}

  void completeLoad(List<Report> reports) {
    _loadCompleter.complete(reports);
  }

  void failLoad(Object error) {
    _loadCompleter.completeError(error);
  }
}
