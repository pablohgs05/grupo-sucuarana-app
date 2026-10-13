/// Text shaping for the offline PDF renderer.
///
/// Dart's standard PDF Helvetica fonts support WinAnsi, not arbitrary Unicode.
/// Keep Portuguese accents intact and make unsupported code points explicit,
/// instead of silently dropping them or drawing replacement boxes.
/// The original report data is never modified.
String safePdfText(String source) {
  final result = StringBuffer();
  for (final rune in source.runes) {
    switch (rune) {
      case 0x2018: // Left curly apostrophe
      case 0x2019: // Right curly apostrophe
      case 0x201A:
      case 0x201B:
        result.write("'");
      case 0x201C:
      case 0x201D:
      case 0x201E:
      case 0x201F:
        result.write('"');
      case 0x2010:
      case 0x2011:
      case 0x2012:
      case 0x2013:
      case 0x2014:
      case 0x2015:
      case 0x2212:
        result.write('-');
      case 0x2022:
      case 0x25CF:
      case 0x25E6:
      case 0x25AA:
        result.write('-');
      case 0x2026:
        result.write('...');
      case 0x2192:
      case 0x21D2:
        result.write(' -> ');
      case 0x2190:
      case 0x21D0:
        result.write(' <- ');
      case 0x2194:
        result.write(' <-> ');
      case 0x2713:
      case 0x2714:
      case 0x2705:
        result.write('[OK]');
      case 0x274C:
      case 0x2717:
        result.write('[X]');
      case 0x26A0:
        result.write('[ATENCAO]');
      case 0x00A0:
      case 0x2007:
      case 0x202F:
        result.write(' ');
      case 0x200B:
      case 0x200C:
      case 0x200D:
      case 0xFE0E:
      case 0xFE0F:
      case 0xFEFF:
        // Invisible joiners and presentation selectors cannot be rendered.
        break;
      default:
        if ((rune >= 0x20 && rune <= 0x7E) ||
            (rune >= 0xA1 && rune <= 0xFF) ||
            rune == 0x0A ||
            rune == 0x09) {
          result.writeCharCode(rune);
        } else if (rune == 0x0D) {
          // Ignore CR; preserve LF on Windows line endings.
          break;
        } else {
          // An explicit marker preserves the code point in a readable form.
          result.write('[U+${rune.toRadixString(16).toUpperCase()}]');
        }
    }
  }
  return result.toString();
}

/// Break an extended narrative into short, inseparable layout units.
///
/// The source paragraph is not edited in the report; chunking is limited to
/// pagination. Each chunk fits far below one A4 body page in normal font sizes,
/// preventing an isolated last word on the following page.
List<PdfNarrativeChunk> splitPdfNarrative(
  String value, {
  int targetCharacters = 260,
}) {
  if (targetCharacters < 80) {
    throw ArgumentError.value(targetCharacters, 'targetCharacters');
  }

  final paragraphs =
      value.replaceAll('\r\n', '\n').trim().split(RegExp(r'\n[ \t]*\n'));
  final result = <PdfNarrativeChunk>[];

  for (final paragraph in paragraphs) {
    if (paragraph.trim().isEmpty) continue;

    final words = RegExp(r'\S+\s*')
        .allMatches(paragraph.trim())
        .map((match) => match.group(0)!)
        .toList(growable: false);
    if (words.isEmpty) continue;

    final groupCount = (paragraph.length / targetCharacters).ceil();
    final desiredLength = (paragraph.length / groupCount).ceil();
    final chunks = <String>[];
    var current = StringBuffer();

    for (final token in words) {
      if (current.isNotEmpty &&
          current.length >= desiredLength &&
          chunks.length < groupCount - 1) {
        chunks.add(current.toString().trimRight());
        current = StringBuffer();
      }
      current.write(token);
    }
    if (current.isNotEmpty) chunks.add(current.toString().trimRight());

    // Never leave a one-word trailing fragment by itself.
    if (chunks.length > 1 && chunks.last.length < 70) {
      chunks[chunks.length - 2] = '${chunks[chunks.length - 2]} ${chunks.last}';
      chunks.removeLast();
    }

    for (var index = 0; index < chunks.length; index++) {
      result.add(PdfNarrativeChunk(
        text: chunks[index],
        paragraphEnd: index == chunks.length - 1,
      ));
    }
  }

  return List<PdfNarrativeChunk>.unmodifiable(result);
}

class PdfNarrativeChunk {
  const PdfNarrativeChunk({required this.text, required this.paragraphEnd});

  final String text;
  final bool paragraphEnd;
}
