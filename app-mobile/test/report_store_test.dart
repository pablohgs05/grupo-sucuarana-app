import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_store.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDirectory;
  late String databasePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory =
        await Directory.systemTemp.createTemp('grupo_sucuarana_store_test_');
    databasePath = p.join(tempDirectory.path, 'reports.db');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('persists reports after closing and reopening the database', () async {
    final report = _fakeReport();

    final firstStore = ReportStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    await firstStore.save([report]);
    await firstStore.close();

    final reopenedStore = ReportStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    final loaded = await reopenedStore.load();
    await reopenedStore.close();

    expect(loaded, hasLength(1));
    expect(loaded.single.toJson(), equals(report.toJson()));
  });

  test('upsert updates one report without deleting the others', () async {
    final first = _fakeReport(id: 'report-001', title: 'Primeiro');
    final second = _fakeReport(id: 'report-002', title: 'Segundo');

    final store = ReportStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    await store.save([first, second]);

    final updatedFirst = _fakeReport(
      id: first.id,
      title: 'Primeiro atualizado',
      updatedAt: DateTime.utc(2026, 10, 1, 13),
      lifecycle: ReportLifecycle.draft,
      lastEditedStep: 3,
    );
    await store.upsert(updatedFirst);

    final loaded = await store.load();
    await store.close();

    expect(loaded, hasLength(2));
    expect(
      loaded.singleWhere((report) => report.id == first.id).title,
      'Primeiro atualizado',
    );
    expect(
      loaded.singleWhere((report) => report.id == second.id).title,
      'Segundo',
    );
  });

  test('migrates legacy SharedPreferences data without deleting it', () async {
    final report = _fakeReport();
    final legacyJson = jsonEncode(report.toJson());
    SharedPreferences.setMockInitialValues({
      'structured_reports': [legacyJson],
    });

    final store = ReportStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    final loaded = await store.load();
    await store.close();

    expect(loaded, hasLength(1));
    expect(loaded.single.toJson(), equals(report.toJson()));

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('structured_reports'),
      equals([legacyJson]),
    );
    expect(
      preferences.getBool('structured_reports_sqlite_migrated_v1'),
      isTrue,
    );
  });
}

Report _fakeReport({
  String id = 'report-test-001',
  String title = 'Operação de teste',
  DateTime? updatedAt,
  ReportLifecycle lifecycle = ReportLifecycle.readyForReview,
  int lastEditedStep = 0,
}) {
  final timestamp = updatedAt ?? DateTime.utc(2026, 10, 1, 12, 30);
  return Report(
    id: id,
    identification: Identification(
      title: title,
      date: DateTime.utc(2026, 10, 1),
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
    teams: const ['Equipe Alpha'],
    resources: const ['Recurso de teste'],
    conclusion: 'Conclusão fictícia.',
    attachments: const [],
    createdAt: DateTime.utc(2026, 10, 1, 12),
    updatedAt: timestamp,
    lifecycle: lifecycle,
    lastEditedStep: lastEditedStep,
    syncStatus: SyncStatus.pending,
  );
}
