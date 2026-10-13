/// Prepare PDF text for the four bundled Inria Sans font variants.
///
/// Portuguese accents, dashes, quotation marks, bullets and arrows remain
/// unchanged. Rare symbols missing from the bundled font are represented by
/// a readable fallback, never a missing-glyph box. Original data is preserved.
/// The supported intervals are the common cmap of the four pinned font files.
/// See assets/fonts/OFL.txt for their license.
String safePdfText(String source) {
  final result = StringBuffer();
  for (final rune in source.runes) {
    if (rune == 0x0A) {
      result.write('\n');
      continue;
    }
    if (rune == 0x0D) continue;
    if (rune == 0x09 || rune == 0x00A0 || rune == 0x2007 || rune == 0x202F) {
      result.write(' ');
      continue;
    }
    if (rune == 0x200B ||
        rune == 0x200C ||
        rune == 0x200D ||
        rune == 0xFE0E ||
        rune == 0xFE0F ||
        rune == 0xFEFF) {
      continue;
    }
    if (_supportedByInria(rune)) {
      result.writeCharCode(rune);
      continue;
    }

    switch (rune) {
      case 0x2010:
      case 0x2011:
      case 0x2012:
      case 0x2015:
      case 0x2212:
        result.write('-');
      case 0x25CF:
      case 0x25E6:
      case 0x25AA:
        result.write('-');
      case 0x21D2:
        result.write(' -> ');
      case 0x21D0:
        result.write(' <- ');
      case 0x21D4:
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
      default:
        result.write('[U+${rune.toRadixString(16).toUpperCase()}]');
    }
  }
  return result.toString();
}

bool _supportedByInria(int codepoint) {
  var low = 0;
  var high = _inriaGlyphRanges.length - 1;
  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final range = _inriaGlyphRanges[mid];
    if (codepoint < range.$1) {
      high = mid - 1;
    } else if (codepoint > range.$2) {
      low = mid + 1;
    } else {
      return true;
    }
  }
  return false;
}

const _inriaGlyphRanges = <(int, int)>[
  (0xD, 0xD),
  (0x20, 0x7E),
  (0xA0, 0x17E),
  (0x192, 0x192),
  (0x218, 0x21B),
  (0x237, 0x237),
  (0x2C6, 0x2C7),
  (0x2D8, 0x2DD),
  (0x3C0, 0x3C0),
  (0x1E80, 0x1E85),
  (0x1E9E, 0x1E9E),
  (0x1EF2, 0x1EF3),
  (0x2013, 0x2014),
  (0x2018, 0x201A),
  (0x201C, 0x201E),
  (0x2020, 0x2022),
  (0x2026, 0x2026),
  (0x2030, 0x2030),
  (0x2039, 0x203A),
  (0x2044, 0x2044),
  (0x2070, 0x2070),
  (0x2074, 0x2079),
  (0x2080, 0x2089),
  (0x20AC, 0x20AC),
  (0x20B9, 0x20B9),
  (0x2113, 0x2113),
  (0x2116, 0x2116),
  (0x2122, 0x2122),
  (0x2126, 0x2126),
  (0x212E, 0x212E),
  (0x2153, 0x2154),
  (0x215B, 0x215E),
  (0x2190, 0x2199),
  (0x2202, 0x2202),
  (0x2206, 0x2206),
  (0x220F, 0x220F),
  (0x2211, 0x2212),
  (0x2215, 0x2215),
  (0x221A, 0x221A),
  (0x221E, 0x221E),
  (0x222B, 0x222B),
  (0x2248, 0x2248),
  (0x2260, 0x2260),
  (0x2264, 0x2265),
  (0x25CA, 0x25CA),
  (0xF6C3, 0xF6C3),
  (0xFB00, 0xFB04),
];

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
