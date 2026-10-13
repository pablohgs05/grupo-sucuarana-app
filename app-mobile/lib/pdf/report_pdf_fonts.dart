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
  final fontBytes = await Future.wait([
    rootBundle.load('$directory/InriaSans-Regular.ttf'),
    rootBundle.load('$directory/InriaSans-Bold.ttf'),
    rootBundle.load('$directory/InriaSans-Italic.ttf'),
    rootBundle.load('$directory/InriaSans-BoldItalic.ttf'),
  ]);

  return pw.ThemeData.withFont(
    base: pw.Font.ttf(fontBytes[0]),
    bold: pw.Font.ttf(fontBytes[1]),
    italic: pw.Font.ttf(fontBytes[2]),
    boldItalic: pw.Font.ttf(fontBytes[3]),
  );
}
