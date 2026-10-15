import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/report_model.dart';
import 'package:grupo_sucuarana_app/report_sync.dart';

void main() {
  test('envia JSON completo, data UTC e nao altera o estado local', () async {
    final report = _fakeReport(
      lifecycle: ReportLifecycle.readyForReview,
      syncStatus: SyncStatus.pending,
    );
    final original = report.toJson();
    final client = Dio();
    addTearDown(() => client.close(force: true));
    RequestOptions? sent;
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = options;
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    );
    await ReportSync(client: client).send(report);
    expect(sent!.method, 'POST');
    expect(Uri.parse(sent!.path).path, '/api/reports/sync');
    expect(sent!.contentType, Headers.jsonContentType);
    expect(sent!.data, {
      'id': report.id,
      'title': report.title,
      'location': report.location,
      'description': report.conclusion,
      'occurredAt': report.identification.date.toUtc().toIso8601String(),
      'data': original,
    });
    expect(report.toJson(), original);
  });

  for (final failure in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badResponse,
  ]) {
    test('propaga $failure sem marcar relatorio como sincronizado', () async {
      final report = _fakeReport(
        lifecycle: ReportLifecycle.readyForReview,
        syncStatus: SyncStatus.pending,
      );
      final original = report.toJson();
      final client = Dio();
      addTearDown(() => client.close(force: true));
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: failure,
                response: failure == DioExceptionType.badResponse
                    ? Response(requestOptions: options, statusCode: 500)
                    : null,
              ),
            );
          },
        ),
      );
      await expectLater(
        ReportSync(client: client).send(report),
        throwsA(isA<DioException>().having((e) => e.type, 'type', failure)),
      );
      expect(report.toJson(), original);
      expect(isReportSyncEligible(report), isTrue);
    });
  }

  test('rascunho pendente nunca entra na fila de sincronizacao', () {
    final draft = _fakeReport(
      lifecycle: ReportLifecycle.draft,
      syncStatus: SyncStatus.pending,
    );

    expect(isReportSyncEligible(draft), isFalse);
    expect(reportsEligibleForSync([draft]), isEmpty);
  });

  test('relatorio pronto para revisao e pendente entra na fila', () {
    final ready = _fakeReport(
      lifecycle: ReportLifecycle.readyForReview,
      syncStatus: SyncStatus.pending,
    );

    expect(isReportSyncEligible(ready), isTrue);
    expect(reportsEligibleForSync([ready]), [ready]);
  });

  test('fila aceita somente readyForReview pendente', () {
    final draft = _fakeReport(
      id: 'draft',
      lifecycle: ReportLifecycle.draft,
      syncStatus: SyncStatus.pending,
    );
    final ready = _fakeReport(
      id: 'ready',
      lifecycle: ReportLifecycle.readyForReview,
      syncStatus: SyncStatus.pending,
    );
    final alreadySynced = _fakeReport(
      id: 'synced',
      lifecycle: ReportLifecycle.readyForReview,
      syncStatus: SyncStatus.synced,
    );
    final finalized = _fakeReport(
      id: 'finalized',
      lifecycle: ReportLifecycle.finalized,
      syncStatus: SyncStatus.pending,
    );

    expect(reportsEligibleForSync([draft, ready, alreadySynced, finalized]), [
      ready,
    ]);
  });
}

Report _fakeReport({
  String id = 'report-sync-test',
  required ReportLifecycle lifecycle,
  required SyncStatus syncStatus,
}) {
  final timestamp = DateTime.utc(2026, 10, 1, 18);
  return Report(
    id: id,
    identification: Identification(
      title: 'Relatorio ficticio',
      date: timestamp,
      coordinator: 'Equipe ficticia',
    ),
    missing: const MissingPerson(
      name: 'Pessoa ficticia',
      lastSeen: 'Local ficticio',
      contact: 'Contato ficticio',
    ),
    operation: const Operation(
      location: 'Cidade ficticia',
      start: '08:00',
      end: '12:00',
    ),
    physicalDescription: 'Descricao ficticia.',
    clothing: 'Vestimenta ficticia.',
    health: 'Sem dados reais.',
    procedures: 'Procedimentos de teste.',
    teams: const <String>['Equipe Alpha'],
    resources: const <String>['Recurso de teste'],
    conclusion: 'Conclusao ficticia.',
    attachments: const <String>[],
    createdAt: timestamp.subtract(const Duration(hours: 1)),
    updatedAt: timestamp,
    lifecycle: lifecycle,
    lastEditedStep: 0,
    syncStatus: syncStatus,
  );
}
