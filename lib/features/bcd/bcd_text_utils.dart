import 'dart:convert';

/// Removes the backend " (app)" suffix from display names.
String stripAppSuffix(String name) =>
    name.replaceAll(RegExp(r'\s*\(app\)\s*$', caseSensitive: false), '').trim();

/// Fixes Mojibake: UTF-8 bytes mis-read as Latin-1.
/// e.g. "Ã¶" (U+00C3 U+00B6) → bytes 0xC3 0xB6 → UTF-8 → "ö"
String fixBcdEncoding(String text) {
  if (text.codeUnits.every((c) => c < 256)) {
    try {
      return utf8.decode(text.codeUnits.toList());
    } catch (_) {
      // Strict decode failed — likely a lone 2-byte sequence starter (e.g. trailing "Â" = 0xC2)
      // without its continuation byte. Drop such orphaned bytes and retry.
      final bytes = text.codeUnits.toList();
      final cleaned = <int>[];
      for (var i = 0; i < bytes.length; i++) {
        final b = bytes[i];
        if (b >= 0xC0 && b <= 0xDF) {
          final next = i + 1 < bytes.length ? bytes[i + 1] : -1;
          if (next >= 0x80 && next <= 0xBF) {
            cleaned.add(b); // valid 2-byte pair — keep
          }
          // else lone leading byte — drop it
        } else {
          cleaned.add(b);
        }
      }
      try {
        return utf8.decode(cleaned);
      } catch (_) {}
    }
  }
  return text;
}

final _emojiRegex = RegExp(
  r'[\u{1F000}-\u{1FAFF}]|[\u{2600}-\u{27BF}]|[\u{FE00}-\u{FEFF}]|\u{200D}',
  unicode: true,
);

/// Strips HTML tags, emojis, and fixes all known encoding issues (Mojibake + HTML entities).
String cleanBcdText(String raw) {
  return fixBcdEncoding(raw)
      .replaceAll(_emojiRegex, '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&auml;', 'ä')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&aring;', 'å')
      .replaceAll('&Auml;', 'Ä')
      .replaceAll('&Ouml;', 'Ö')
      .replaceAll('&Aring;', 'Å')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&uuml;', 'ü')
      .replaceAll('&apos;', "'")
      .trim();
}

/// Similar to [cleanBcdText] but keeps meaningful line breaks.
/// Useful for checklist/document-like content where `\n` should render as new lines.
String cleanBcdMultilineText(String raw) {
  final text = fixBcdEncoding(raw)
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll('\\n', '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&auml;', 'ä')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&aring;', 'å')
      .replaceAll('&Auml;', 'Ä')
      .replaceAll('&Ouml;', 'Ö')
      .replaceAll('&Aring;', 'Å')
      .replaceAll('&eacute;', 'é')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&uuml;', 'ü')
      .replaceAll('&apos;', "'");

  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n')
      .trim();
}
