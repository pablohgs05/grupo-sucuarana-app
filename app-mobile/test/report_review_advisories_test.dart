import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/operational_report.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_review_advisories.dart';
import 'package:grupo_sucuarana_app/search_triage.dart';

void main() {
  test('respostas vazias não criam obrigatoriedades nem avisos', () {
    expect(reviewReportAdvisories(_report()), isEmpty);
  });

  test('identifica idade e altura explicitamente improváveis', () {
    final report = _report(
      physical: PhysicalDescription.empty.copyWith(
        age: '3000 anos',
        height: '173m',
      ),
    );

    final warnings = reviewReportAdvisories(report);
    expect(warnings.map((item) => item.id), <String>[
      'physical-age',
      'physical-height',
    ]);
    expect(
      warnings.every((item) => item.sectionId == 'physicalDescription'),
      isTrue,
    );
    expect(warnings.map((item) => item.message).join(' '), isNot(contains('3000')));
  });

  test('valores plausíveis e unidades comuns não geram falso aviso', () {
    for (final height in <String>['1,73 m', '173cm', '150 cm']) {
      final report = _report(
        physical: PhysicalDescription.empty.copyWith(
          age: '32 anos',
          height: height,
        ),
      );
      expect(reviewReportAdvisories(report), isEmpty);
    }
  });

  test('cronologia anterior é apenas indicada para conferência', () {
    final report = _report(
      metadata: const TriageMetadata(
        formNumber: '',
        factDate: '05/10/2026',
        factTime: '10:00',
        noticeDate: '05/10/2026',
        noticeTime: '09:59',
      ),
    );
    final warnings = reviewReportAdvisories(report);
    expect(warnings.map((item) => item.id), contains('notice-before-fact'));
    expect(warnings.single.sectionId, 'triageMetadata');
  });

  test('aviso depois de meia-noite não provoca alarme indevido', () {
    final report = _report(
      metadata: const TriageMetadata(
        formNumber: '',
        factDate: '05/10/2026',
        factTime: '23:50',
        noticeDate: '06/10/2026',
        noticeTime: '00:05',
      ),
    );
    expect(reviewReportAdvisories(report), isEmpty);
  });

  test('datas e horários inválidos são sinalizados sem regravar dados', () {
    const input = TriageMetadata(
      formNumber: '',
      factDate: '32/10/2026',
      factTime: '25:10',
      noticeDate: '05/10/2026',
      noticeTime: '10:00',
    );
    final report = _report(metadata: input);
    final warnings = reviewReportAdvisories(report);

    expect(warnings.map((item) => item.id), containsAll([
      'fact-date-format',
      'fact-time-format',
    ]));
    expect(warnings.map((item) => item.id), isNot(contains('notice-before-fact')));
    expect(report.searchTriage.metadata.factDate, '32/10/2026');
  });

  test('frase de último avistamento claramente impossível é avisada', () {
    final report = _report(
      lastSeen: LastSeen.empty.copyWith(when: 'Dia 32 de agosto'),
    );
    expect(
      reviewReportAdvisories(report).map((item) => item.id),
      contains('last-seen-date'),
    );
    expect(
      reviewReportAdvisories(
        _report(lastSeen: LastSeen.empty.copyWith(when: 'Ontem')),
      ),
      isEmpty,
    );
  });

  test('dia 29 em fevereiro respeita ano bissexto quando informado', () {
    expect(
      reviewReportAdvisories(
        _report(
          lastSeen: LastSeen.empty.copyWith(
            when: 'Dia 29 de fevereiro de 2024',
          ),
        ),
      ),
      isEmpty,
    );
    expect(
      reviewReportAdvisories(
        _report(
          lastSeen: LastSeen.empty.copyWith(
            when: 'Dia 29 de fevereiro de 2025',
          ),
        ),
      ).map((item) => item.id),
      contains('last-seen-date'),
    );
  });
}

Report _report({
  TriageMetadata metadata = TriageMetadata.empty,
  PhysicalDescription physical = PhysicalDescription.empty,
  LastSeen lastSeen = LastSeen.empty,
}) =>
    Report(
      id: 'aviso-ficticio-001',
      identification: Identification(
        title: 'Teste de avisos',
        date: DateTime.utc(2026, 10, 5),
        coordinator: 'Equipe fictícia',
      ),
      searchTriage: SearchTriage.empty.copyWith(
        metadata: metadata,
        physicalDescription: physical,
        lastSeen: lastSeen,
      ),
      operation: const Operation(
        location: 'Área fictícia',
        start: '',
        end: '',
      ),
      operationalContent: OperationalReportContent.empty,
      createdAt: DateTime.utc(2026, 10, 5),
      updatedAt: DateTime.utc(2026, 10, 5),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 0,
      syncStatus: SyncStatus.pending,
    );
