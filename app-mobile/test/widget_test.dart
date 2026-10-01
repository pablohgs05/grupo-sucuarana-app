import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('exibe a tela inicial do aplicativo', (tester) async {
    await tester.pumpWidget(const GrupoSucuaranaApp());

    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }

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
