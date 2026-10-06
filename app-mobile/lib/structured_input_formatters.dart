import 'package:flutter/services.dart';

class DateDigitsInputFormatter extends TextInputFormatter {
  const DateDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digits(newValue.text, 8);
    final formatted = _formatDateDigits(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _selectionOffset(
          formatted,
          _digitCountBeforeSelection(newValue),
        ),
      ),
    );
  }
}

class TimeDigitsInputFormatter extends TextInputFormatter {
  const TimeDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digits(newValue.text, 4);
    final formatted = _formatTimeDigits(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _selectionOffset(
          formatted,
          _digitCountBeforeSelection(newValue),
        ),
      ),
    );
  }
}

String? validateDateInput(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
  if (match == null) return 'Use o formato DD/MM/AAAA.';

  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);

  if (year < 1) return 'Informe uma data válida.';

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return 'Informe uma data válida.';
  }

  return null;
}

String? validateTimeInput(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text);
  if (match == null) return 'Use o formato HH:MM.';

  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    return 'Informe um horário válido.';
  }

  return null;
}

String _digits(String text, int maxLength) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= maxLength) return digits;
  return digits.substring(0, maxLength);
}

String _formatDateDigits(String digits) {
  if (digits.length <= 2) return digits;
  if (digits.length <= 4) {
    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }
  return '${digits.substring(0, 2)}/'
      '${digits.substring(2, 4)}/'
      '${digits.substring(4)}';
}

String _formatTimeDigits(String digits) {
  if (digits.length <= 2) return digits;
  return '${digits.substring(0, 2)}:${digits.substring(2)}';
}

int _digitCountBeforeSelection(TextEditingValue value) {
  final selectionOffset = value.selection.baseOffset;
  final offset = selectionOffset < 0
      ? 0
      : selectionOffset > value.text.length
          ? value.text.length
          : selectionOffset;
  return value.text
      .substring(0, offset)
      .replaceAll(RegExp(r'\D'), '')
      .length;
}

int _selectionOffset(String formatted, int digitCount) {
  if (digitCount <= 0) return 0;

  var seen = 0;
  for (var index = 0; index < formatted.length; index++) {
    if (RegExp(r'\d').hasMatch(formatted[index])) {
      seen++;
      if (seen == digitCount) return index + 1;
    }
  }

  return formatted.length;
}
