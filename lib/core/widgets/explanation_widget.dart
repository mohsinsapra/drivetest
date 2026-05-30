import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import '../models/question.dart';

// ── Parsed explanation ────────────────────────────────────────────────────────

class _Parsed {
  final String? text;
  final String? imageUrl;
  const _Parsed({this.text, this.imageUrl});
  bool get hasText => text != null && text!.trim().isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Parse [raw] into optional text + optional image URL.
///
/// Cases handled:
///   1. Full http(s) URL that looks like an image → image only
///   2. Bare path with image extension (legacy) → image via fetchImage
///   3. HTML text (may contain embedded <img>) → strip tags, decode entities,
///      extract first <img src> if present → text + optional image
_Parsed _parse(
    String raw, String licenceId, String categoryId, ApiService api) {
  if (raw.isEmpty) return const _Parsed();

  // 1. Already a full image URL
  if ((raw.startsWith('http://') || raw.startsWith('https://'))) {
    final noQuery = raw.split('?').first.split('/').last.toLowerCase();
    if (RegExp(r'\.(png|jpg|jpeg|gif|webp)$').hasMatch(noQuery)) {
      return _Parsed(imageUrl: raw);
    }
  }

  // 2. Bare image path — no spaces, has image extension (legacy questions)
  if (!raw.contains(' ') &&
      !raw.contains('<') &&
      RegExp(r'\.(png|jpg|jpeg|gif|webp)$', caseSensitive: false)
          .hasMatch(raw)) {
    return _Parsed(imageUrl: api.fetchImage(licenceId, categoryId, raw));
  }

  // 3. HTML / plain text — extract embedded image and strip markup
  String? embeddedUrl;
  final imgRegex = RegExp(
    r"""<img[^>]+src=['"]([^'"]+)['"]""",
    caseSensitive: false,
  );
  final imgSrcMatch = imgRegex.firstMatch(raw);
  if (imgSrcMatch != null) {
    final src = imgSrcMatch.group(1) ?? '';
    if (src.isNotEmpty) {
      embeddedUrl = src.startsWith('http')
          ? src
          : api.fetchImage(licenceId, categoryId, src);
    }
  }

  // Strip all HTML tags
  String text = raw.replaceAll(RegExp(r'<[^>]+>'), ' ');
  // Decode HTML entities
  text = _decodeEntities(text);
  // Collapse whitespace
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  return _Parsed(
    text: text.isNotEmpty ? text : null,
    imageUrl: embeddedUrl,
  );
}

String _decodeEntities(String s) {
  // Numeric entities: &#160; or &#xA0;
  s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    return String.fromCharCode(int.parse(m.group(1)!, radix: 16));
  });
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    return String.fromCharCode(int.parse(m.group(1)!));
  });
  // Named entities (common + Swedish)
  const map = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&auml;': 'ä',
    '&Auml;': 'Ä',
    '&ouml;': 'ö',
    '&Ouml;': 'Ö',
    '&aring;': 'å',
    '&Aring;': 'Å',
    '&eacute;': 'é',
    '&egrave;': 'è',
    '&aacute;': 'á',
    '&agrave;': 'à',
    '&uuml;': 'ü',
    '&Uuml;': 'Ü',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
    '&mdash;': '—',
    '&ndash;': '–',
    '&hellip;': '…',
    '&laquo;': '«',
    '&raquo;': '»',
  };
  for (final e in map.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ExplanationWidget extends StatelessWidget {
  final Question question;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;

  const ExplanationWidget({
    super.key,
    required this.question,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    if (question.answerExplanation.isEmpty) return const SizedBox.shrink();

    final parsed = _parse(
      question.answerExplanation,
      licenceId,
      categoryId,
      apiService,
    );

    if (!parsed.hasText && !parsed.hasImage) return const SizedBox.shrink();

    return ExpandableNotifier(
      initialExpanded: true,
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          hasIcon: true,
          iconColor: Theme.of(context).colorScheme.onSurface,
          iconPlacement: ExpandablePanelIconPlacement.right,
          tapBodyToCollapse: false,
          tapBodyToExpand: false,
        ),
        header: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Explanation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        collapsed: const SizedBox.shrink(),
        expanded: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text
              if (parsed.hasText)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    parsed.text!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),

              // Image
              if (parsed.hasImage)
                GestureDetector(
                  onTap: () => showImageViewer(context, [parsed.imageUrl!]),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                      maxWidth: MediaQuery.of(context).size.width,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: parsed.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
