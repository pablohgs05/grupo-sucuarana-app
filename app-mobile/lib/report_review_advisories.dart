import 'report_model.dart';
import 'structured_input_formatters.dart';

/// A non-blocking suggestion shown only when reviewing a report.
///
/// Messages intentionally omit input values to avoid copying personal data
/// into UI diagnostics, logs, or automated test output.
class ReviewAdvisory {
  const ReviewAdvisory({
    required this.id,
    required this.sectionId,
    required this.message,
  });

  final String id;
  final String sectionId;
  final String message;
}

/// Conservative checks for obvious format/chronology issues.
///
/// This is NOT a replacement for client-approved validation rules.
/// Unknown or free-form answers stay valid and never become mandatory.
List<ReviewAdvisory> reviewReportAdvisories(Report report) {
  final warnings = <ReviewAdvisory>[];
  final metadata = report.searchTriage.metadata;

  void checkDate(String field, String value) {
    if (value.trim().isNotEmpty && validateDateInput(value) != null) {
      warnings.add(ReviewAdvisory(
        id: field + '-format',
        sectionId: 'triageMetadata',
        message: field == 'fact-date'
            ? 'Confira a data do fato: formato ou dia inválido.'
            : 'Confira a data do aviso: formato ou dia inválido.',
      ));
    }
  }

  void checkTime(String field, String value) {
    if (value.trim().isNotEmpty && validateTimeInput(value) != null) {
      warnings.add(ReviewAdvisory(
        id: field + '-format',
        sectionId: 'triageMetadata',
        message: field == 'fact-time'
            ? 'Confira o horário do fato: use HH:MM válido.'
            : 'Confira o horário do aviso: use HH:MM válido.',
      ));
    }
  }

  checkDate('fact-date', metadata.factDate);
  checkDate('notice-date', metadata.noticeDate);
  checkTime('fact-time', metadata.factTime);
  checkTime('notice-time', metadata.noticeTime);

  final factDate = _parseDate(metadata.factDate);
  final noticeDate = _parseDate(metadata.noticeDate);
  if (factDate != null && noticeDate != null) {
    final earlierDay = noticeDate.isBefore(factDate);
    final sameDay = noticeDate.isAtSameMomentAs(factDate);
    final factMinutes = _parseMinutes(metadata.factTime);
    final noticeMinutes = _parseMinutes(metadata.noticeTime);
    if (earlierDay ||
        (sameDay &&
            factMinutes != null &&
            noticeMinutes != null &&
            noticeMinutes < factMinutes)) {
      warnings.add(const ReviewAdvisory(
        id: 'notice-before-fact',
        sectionId: 'triageMetadata',
        message: 'O aviso parece anterior ao fato. Confira a cronologia.',
      ));
    }
  }

  if (_impossibleLastSeenDay(report.searchTriage.lastSeen.when)) {
    warnings.add(const ReviewAdvisory(
      id: 'last-seen-date',
      sectionId: 'lastSeen',
      message: 'O dia informado no último avistamento parece inválido.',
    ));
  }

  final age = _parseAge(report.searchTriage.physicalDescription.age);
  if (age != null && (age < 0 || age > 120)) {
    warnings.add(const ReviewAdvisory(
      id: 'physical-age',
      sectionId: 'physicalDescription',
      message: 'Idade muito incomum: confira o valor informado.',
    ));
  }

  final height = _parseHeightMetres(
    report.searchTriage.physicalDescription.height,
  );
  if (height != null && (height < 0.3 || height > 2.8)) {
    warnings.add(const ReviewAdvisory(
      id: 'physical-height',
      sectionId: 'physicalDescription',
      message: 'Altura muito incomum: confira o número e a unidade.',
    ));
  }

  return List<ReviewAdvisory>.unmodifiable(warnings);
}

DateTime? _parseDate(String text) {
  if (text.trim().isEmpty || validateDateInput(text) != null) return null;
  final parts = text.trim().split('/');
  return DateTime.utc(
    int.parse(parts[2]),
    int.parse(parts[1]),
    int.parse(parts[0]),
  );
}

int? _parseMinutes(String text) {
  if (text.trim().isEmpty || validateTimeInput(text) != null) return null;
  final parts = text.trim().split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

int? _parseAge(String text) {
  final match = RegExp(r'^(-?\d+)\s*(?:anos?)?$', caseSensitive: false)
      .firstMatch(text.trim());
  return match == null ? null : int.tryParse(match.group(1)!);
}

double? _parseHeightMetres(String text) {
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*(cm|cent[ií]metros?|m|metros?)$',
    caseSensitive: false,
  ).firstMatch(text.trim());
  if (match == null) return null;

  final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (value == null) return null;
  final unit = match.group(2)!.toLowerCase();
  return unit.startsWith('c') ? value / 100 : value;
}

/// Only evaluate fully recognized Portuguese calendar phrases. Free text
/// such as "ontem", "há alguns dias" and uncertain reports are untouched.
bool _impossibleLastSeenDay(String value) {
  final match = RegExp(
    r'^(?:dia\s+)?(\d{1,2})\s+de\s+'
    r'(janeiro|fevereiro|março|marco|abril|maio|junho|julho|agosto|'
    r'setembro|outubro|novembro|dezembro)'
    r'(?:\s+de\s+(\d{4}))?$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return false;

  const months = <String, int>{
    'janeiro': 1,
    'fevereiro': 2,
    'março': 3,
    'marco': 3,
    'abril': 4,
    'maio': 5,
    'junho': 6,
    'julho': 7,
    'agosto': 8,
    'setembro': 9,
    'outubro': 10,
    'novembro': 11,
    'dezembro': 12,
  };

  final day = int.parse(match.group(1)!);
  final month = months[match.group(2)!.toLowerCase()]!;
  final year = match.group(3) == null ? 2024 : int.parse(match.group(3)!);
  if (year < 1) return true;
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  return day < 1 || day > daysInMonth;
}
