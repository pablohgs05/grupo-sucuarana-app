import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/main.dart';

void main() {
  testWidgets('exibe a tela inicial do aplicativo', (tester) async {
    await tester.pumpWidget(const GrupoSucuaranaApp());

    expect(find.text('Grupo Suçuarana'), findsOneWidget);
    expect(find.textContaining('Base do aplicativo pronta'), findsOneWidget);
  });
}
