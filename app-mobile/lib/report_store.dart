import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'report_model.dart';

class ReportStore {
  ReportStore({
    DatabaseFactory? factory,
    String? databasePath,
  })  : _databaseFactory = factory ?? databaseFactory,
        _databasePath = databasePath;

  static const _databaseName = 'grupo_sucuarana.db';
  static const _databaseVersion = 1;
  static const _reportSchemaVersion = 1;
  static const _table = 'reports';

  // Kept only to migrate installations created before SQLite became
  // the local source of truth. The legacy payload is intentionally preserved.
  static const _legacyKey = 'structured_reports';
  static const _legacyMigrationDoneKey =
      'structured_reports_sqlite_migrated_v1';

  final DatabaseFactory _databaseFactory;
  final String? _databasePath;
  Future<Database>? _databaseFuture;

  Future<List<Report>> load() async {
    final db = await _open();
    final rows = await db.query(_table, orderBy: 'updated_at DESC');

    return rows
        .map(
          (row) => Report.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(row['payload_json']! as String) as Map,
            ),
          ),
        )
        .toList();
  }

  Future<void> save(List<Report> reports) async {
    final db = await _open();
    final incomingIds = reports.map((report) => report.id).toSet();

    await db.transaction((transaction) async {
      for (final report in reports) {
        final existing = await transaction.query(
          _table,
          columns: const ['id'],
          where: 'id = ?',
          whereArgs: [report.id],
          limit: 1,
        );

        if (existing.isEmpty) {
          await transaction.insert(_table, _insertValues(report));
        } else {
          await transaction.update(
            _table,
            _updateValues(report),
            where: 'id = ?',
            whereArgs: [report.id],
          );
        }
      }

      final storedRows = await transaction.query(
        _table,
        columns: const ['id'],
      );
      for (final row in storedRows) {
        final id = row['id']! as String;
        if (!incomingIds.contains(id)) {
          await transaction.delete(
            _table,
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    });
  }

  Future<void> close() async {
    final databaseFuture = _databaseFuture;
    _databaseFuture = null;
    if (databaseFuture == null) return;

    final database = await databaseFuture;
    await database.close();
  }

  Future<Database> _open() {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final path = _databasePath ??
        p.join(await _databaseFactory.getDatabasesPath(), _databaseName);

    final database = await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (db, _) async {
          await db.execute(
            '''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY NOT NULL,
              schema_version INTEGER NOT NULL,
              payload_json TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
            ''',
          );
          await db.execute(
            'CREATE INDEX idx_reports_updated_at ON $_table(updated_at)',
          );
        },
      ),
    );

    try {
      await _migrateLegacySharedPreferences(database);
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  Future<void> _migrateLegacySharedPreferences(Database database) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_legacyMigrationDoneKey) == true) return;

    final legacyValues =
        preferences.getStringList(_legacyKey) ?? const <String>[];

    // Parse every item before writing anything. If a legacy payload is invalid,
    // the migration fails without partially migrating or deleting the source.
    final reports = legacyValues
        .map(
          (value) => Report.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();

    await database.transaction((transaction) async {
      for (final report in reports) {
        await transaction.insert(
          _table,
          _insertValues(report),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    // Mark the migration as complete, but keep the old data untouched. This
    // prevents stale legacy rows from being reintroduced on later startups.
    await preferences.setBool(_legacyMigrationDoneKey, true);
  }

  Map<String, Object?> _insertValues(Report report) {
    final updatedAt = report.updatedAt.toUtc().toIso8601String();
    return {
      'id': report.id,
      'schema_version': _reportSchemaVersion,
      'payload_json': jsonEncode(report.toJson()),
      'status': report.syncStatus.name,
      'created_at': updatedAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, Object?> _updateValues(Report report) {
    return {
      'schema_version': _reportSchemaVersion,
      'payload_json': jsonEncode(report.toJson()),
      'status': report.syncStatus.name,
      'updated_at': report.updatedAt.toUtc().toIso8601String(),
    };
  }
}
