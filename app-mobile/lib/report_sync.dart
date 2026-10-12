import 'package:dio/dio.dart';

import 'report_model.dart';

bool isReportSyncEligible(Report report) =>
    report.syncStatus == SyncStatus.pending &&
    report.lifecycle == ReportLifecycle.readyForReview;

List<Report> reportsEligibleForSync(Iterable<Report> reports) =>
    reports.where(isReportSyncEligible).toList(growable: false);

class ReportSync {
  ReportSync({Dio? client}) : _client = client ?? Dio();

  final Dio _client;

  Future<void> send(Report report) async {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    await _client.post<void>(
      '$baseUrl/api/reports/sync',
      data: {
        'id': report.id,
        'title': report.title,
        'location': report.location,
        'description': report.conclusion.isEmpty
            ? report.physicalDescription
            : report.conclusion,
        'occurredAt': report.identification.date.toUtc().toIso8601String(),
        'data': report.toJson(),
      },
      options: Options(contentType: Headers.jsonContentType),
    );
  }
}
