import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/main.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_store.dart';

void main() {
  testWidgets('exibe a tela inicial do aplicativo', (tester) async {
    await tester.pumpWidget(
      GrupoSucuaranaApp(reportRepository: _FakeReportRepository()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Grupo Suçuarana'), findsOneWidget);
    expect(find.text('Novo relatório'), findsOneWidget);
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
  @override
  Future<List<Report>> load() async => const [];

  @override
  Future<void> save(List<Report> reports) async {}
}
