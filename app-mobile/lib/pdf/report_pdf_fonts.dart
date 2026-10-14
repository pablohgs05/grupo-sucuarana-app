import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// The four Inria Sans variants are bundled in Flutter assets.
///
/// No font is fetched at PDF-generation time; field devices can remain offline.
/// Sources and license: assets/fonts/OFL.txt (SIL Open Font License 1.1).
Future<pw.ThemeData>? _offlineTheme;

Future<pw.ThemeData> loadOfflinePdfTheme() =>
    _offlineTheme ??= _buildOfflinePdfTheme();

Future<pw.ThemeData> _buildOfflinePdfTheme() async {
  const directory = 'assets/fonts';
  final regular = await rootBundle.load('$directory/InriaSans-Regular.ttf');
  final bold = await rootBundle.load('$directory/InriaSans-Bold.ttf');
  final italic = await rootBundle.load('$directory/InriaSans-Italic.ttf');
  final boldItalic = await rootBundle.load('$directory/InriaSans-BoldItalic.ttf');

  return pw.ThemeData.withFont(
    base: pw.Font.ttf(regular),
    bold: pw.Font.ttf(bold),
    italic: pw.Font.ttf(italic),
    boldItalic: pw.Font.ttf(boldItalic),
  );
}
