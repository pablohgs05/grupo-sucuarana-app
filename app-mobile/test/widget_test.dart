import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/main.dart';

void main() {
  testWidgets('exibe a tela inicial do aplicativo', (tester) async {
    await tester.pumpWidget(const GrupoSucuaranaApp());
    await tester.pump(const Duration(milliseconds: 200));

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
