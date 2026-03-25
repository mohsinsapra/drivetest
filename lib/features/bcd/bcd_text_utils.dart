import 'dart:convert';

/// Fixes Mojibake: UTF-8 bytes mis-read as Latin-1.
/// e.g. "Ã¶" (U+00C3 U+00B6) → bytes 0xC3 0xB6 → UTF-8 → "ö"
String fixBcdEncoding(String text) {
  if (text.codeUnits.every((c) => c < 256)) {
    try {
      return utf8.decode(text.codeUnits.toList());
    } catch (_) {}
  }
  return text;
}

/// Strips HTML tags and fixes all known encoding issues (Mojibake + HTML entities).
String cleanBcdText(String raw) {
  return fixBcdEncoding(raw)
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
