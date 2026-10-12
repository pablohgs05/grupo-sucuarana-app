import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/structured_input_formatters.dart';

void main() {
  group('DateDigitsInputFormatter', () {
    test('insere barras e mantém somente oito dígitos', () {
      final result = const DateDigitsInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '0101202699',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );

      expect(result.text, '01/01/2026');
      expect(result.selection.baseOffset, 10);
    });

    test('ignora caracteres não numéricos digitados ou colados', () {
      final result = const DateDigitsInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '06a10b2026',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );

      expect(result.text, '06/10/2026');
    });
  });

  group('TimeDigitsInputFormatter', () {
    test('insere dois pontos e mantém somente quatro dígitos', () {
      final result = const TimeDigitsInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '093099',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );

      expect(result.text, '09:30');
      expect(result.selection.baseOffset, 5);
    });
  });

  group('validação estruturada', () {
    test('aceita datas reais e rejeita datas impossíveis', () {
      expect(validateDateInput('29/02/2028'), isNull);
      expect(validateDateInput('31/02/2026'), isNotNull);
      expect(validateDateInput('1/1/2026'), isNotNull);
    });

    test('aceita horários de 00:00 a 23:59', () {
      expect(validateTimeInput('00:00'), isNull);
      expect(validateTimeInput('23:59'), isNull);
      expect(validateTimeInput('24:00'), isNotNull);
      expect(validateTimeInput('12:60'), isNotNull);
    });

    test('mantém campos opcionais vazios válidos', () {
      expect(validateDateInput(''), isNull);
      expect(validateTimeInput(''), isNull);
    });
  });
}
