import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/pdf/report_pdf_text.dart';

void main() {
  test('preserva acentos e pontuação do Inria com fallback legível', () {
    const original =
        'Operação fictícia — localização • 13/10/2026 → encerramento ✅ 👽';
    final result = safePdfText(original);

    expect(result, contains('Operação fictícia — localização •'));
    expect(result, contains('13/10/2026 → encerramento'));
    expect(result, contains('[OK]'));
    expect(result, contains('[U+1F47D]'));
    expect(result, contains('—'));
    expect(result, contains('•'));
    expect(original, contains('—'));
  });

  test('aspas curvas, reticências e quebras do Windows ficam legíveis', () {
    final result = safePdfText('“Relatório”…\r\n‘Teste’ — ok');
    expect(result, '“Relatório”…\n‘Teste’ — ok');
  });

  test('converte caracteres desconhecidos sem apagá-los silenciosamente', () {
    expect(safePdfText('A ✓ B ↔ C'), 'A [OK] B ↔ C');
    expect(safePdfText('①'), '[U+2460]');
    expect(safePdfText(''), '');
  });

  test('narrativa longa mantém conteúdo distribuído em grupos curtos', () {
    final narrative = List.filled(
      250,
      'Equipe fictícia verificou o setor de teste.',
    ).join(' ');
    final chunks = splitPdfNarrative(narrative);
    expect(chunks.length, greaterThan(20));
    expect(chunks.every((item) => item.text.trim().isNotEmpty), isTrue);
    expect(chunks.where((item) => item.paragraphEnd), hasLength(1));

    final rebuilt = chunks.map((item) => item.text).join(' ');
    expect(
      rebuilt.replaceAll(RegExp(r'\s+'), ' '),
      narrative.replaceAll(RegExp(r'\s+'), ' '),
    );
    expect(chunks.every((item) => item.text.length < 550), isTrue);
    expect(chunks.last.text.length, greaterThan(50));
  });

  test('quebras de parágrafo são mantidas na divisão', () {
    const value = 'Primeiro parágrafo de teste.\n\nSegundo parágrafo de teste.';
    final chunks = splitPdfNarrative(value);
    expect(chunks.map((x) => x.text), [
      'Primeiro parágrafo de teste.',
      'Segundo parágrafo de teste.',
    ]);
    expect(chunks.every((item) => item.paragraphEnd), isTrue);
  });

  test('tamanho mínimo do fragmento é protegido', () {
    expect(
      () => splitPdfNarrative('Teste', targetCharacters: 20),
      throwsArgumentError,
    );
  });
}
