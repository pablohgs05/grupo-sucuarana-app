import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/report_model.dart';

void main() {
  test('interpreta payload antigo como relatório já salvo', () {
    final updatedAt = DateTime.utc(2026, 10, 1, 12, 30);
    final report = Report.fromJson({
      'id': 'legacy-report',
      'identification': {
        'title': 'Relatório legado fictício',
        'date': DateTime.utc(2026, 10, 1).toIso8601String(),
        'coordinator': 'Equipe fictícia',
      },
      'missing': {
        'name': 'Pessoa fictícia',
        'lastSeen': 'Local fictício',
        'contact': 'Contato fictício',
      },
      'operation': {
        'location': 'Cidade fictícia',
        'start': '08:00',
        'end': '12:00',
      },
      'physicalDescription': '',
      'clothing': '',
      'health': '',
      'procedures': '',
      'teams': <String>[],
      'resources': <String>[],
      'conclusion': '',
      'attachments': <String>[],
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': 'pending',
    });

    expect(report.createdAt, updatedAt);
    expect(report.lifecycle, ReportLifecycle.readyForReview);
    expect(report.lastEditedStep, 0);
  });

  test('preserva lifecycle e posição de edição no JSON novo', () {
    final report = Report(
      id: 'draft-report',
      identification: Identification(
        title: 'Rascunho fictício',
        date: DateTime.utc(2026, 10, 1),
        coordinator: 'Equipe fictícia',
      ),
      missing: const MissingPerson(
        name: '',
        lastSeen: '',
        contact: '',
      ),
      operation: const Operation(
        location: '',
        start: '',
        end: '',
      ),
      physicalDescription: '',
      clothing: '',
      health: '',
      procedures: '',
      teams: const <String>[],
      resources: const <String>[],
      conclusion: '',
      attachments: const <String>[],
      createdAt: DateTime.utc(2026, 10, 1, 9),
      updatedAt: DateTime.utc(2026, 10, 1, 10),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 4,
      syncStatus: SyncStatus.pending,
    );

    final decoded = Report.fromJson(report.toJson());

    expect(decoded.toJson(), report.toJson());
  });
}
