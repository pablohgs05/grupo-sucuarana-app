import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_model.dart';

class ReportStore {
  static const _key = 'structured_reports';

  Future<List<Report>> load() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? <String>[])
        .map((value) => Report.fromJson(jsonDecode(value) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Report> reports) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      reports.map((report) => jsonEncode(report.toJson())).toList(),
    );
  }
}
